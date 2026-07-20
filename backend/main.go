package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"guardai-be/assessment"
	"guardai-be/assessment/agent"
	"guardai-be/config"
	"guardai-be/db"
	"guardai-be/middleware"
	"guardai-be/token"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	migrateOnly := flag.Bool("migrate-only", false, "Run database migrations and exit")
	flag.Parse()

	cfg := config.LoadConfig()

	var level slog.Level
	switch strings.ToLower(cfg.LogLevel) {
	case "debug":
		level = slog.LevelDebug
	case "warn":
		level = slog.LevelWarn
	case "error":
		level = slog.LevelError
	default:
		level = slog.LevelInfo
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: level,
	}))
	slog.SetDefault(logger)

	slog.Info("Initializing database connection...")
	dbPool, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		slog.Error("Failed to initialize database", slog.Any("error", err))
		os.Exit(1)
	}
	defer dbPool.Close()
	slog.Info("Database connection pool initialized successfully.")

	ctx := context.Background()
	slog.Info("Running database migrations...")
	if err := db.RunMigrations(ctx, dbPool); err != nil {
		slog.Error("Failed to run migrations", slog.Any("error", err))
		os.Exit(1)
	}
	slog.Info("Database migrations completed successfully.")

	if *migrateOnly {
		slog.Info("Migration-only run complete. Exiting.")
		return
	}

	tokenRepo := token.NewRepository(dbPool)
	tokenService := token.NewService(tokenRepo, cfg.RPCURL)
	tokenCtrl := token.NewController(tokenService)

	// Initialize Assessment Module & AI Agent
	assessRepo := assessment.NewRepository(dbPool)
	llmClient := agent.NewLLMClient(cfg.LLMAPIKey, cfg.LLMModel)
	riskAgent := agent.NewRiskAgent(llmClient)
	assessService := assessment.NewService(assessRepo, tokenRepo, riskAgent, cfg.LLMModel)
	assessCtrl := assessment.NewController(assessService, os.Getenv("INTERNAL_API_KEY"))

	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":    "ok",
			"service":   "guardai-be",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	mux.HandleFunc("GET /error-test", func(w http.ResponseWriter, r *http.Request) {
		panic(errors.New("this is a simulated uncaught test error"))
	})

	mux.Handle("GET /metrics", promhttp.Handler())

	// Token endpoints
	mux.HandleFunc("GET /api/v1/tokens", tokenCtrl.ListTokens)
	mux.HandleFunc("GET /api/v1/tokens/{address}", tokenCtrl.GetTokenByAddress)
	mux.HandleFunc("GET /api/v1/tokens/{address}/assessments", tokenCtrl.GetAssessmentsByAddress)

	// Assessment endpoints
	mux.HandleFunc("POST /api/v1/assessments", assessCtrl.TriggerAssessment)
	mux.HandleFunc("GET /api/v1/assessments/{id}", assessCtrl.GetAssessmentByID)

	// Swagger endpoints
	mux.HandleFunc("GET /api/v1/swagger/doc.json", func(w http.ResponseWriter, r *http.Request) {
		data, err := os.ReadFile("docs/swagger.json")
		if err != nil {
			data, err = os.ReadFile("../docs/swagger.json")
		}
		if err != nil {
			data, err = os.ReadFile("backend/docs/swagger.json")
		}
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			_ = json.NewEncoder(w).Encode(map[string]string{"error": "swagger.json not found"})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(data)
	})

	mux.HandleFunc("GET /api/v1/swagger/", func(w http.ResponseWriter, r *http.Request) {
		data, err := os.ReadFile("docs/swagger-ui.html")
		if err != nil {
			data, err = os.ReadFile("../docs/swagger-ui.html")
		}
		if err != nil {
			data, err = os.ReadFile("backend/docs/swagger-ui.html")
		}
		if err != nil {
			w.Header().Set("Content-Type", "text/plain")
			w.WriteHeader(http.StatusNotFound)
			_, _ = w.Write([]byte("swagger-ui.html not found"))
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(data)
	})

	handler := middleware.Recovery(middleware.RequestLogger(middleware.PrometheusMetrics(mux)))

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      handler,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	go func() {
		slog.Info("Starting HTTP server", slog.String("port", cfg.Port))
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("HTTP server failed", slog.Any("error", err))
			os.Exit(1)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	<-stop
	slog.Warn("Received shutdown signal. Starting graceful shutdown...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("Error closing HTTP server", slog.Any("error", err))
	} else {
		slog.Info("HTTP server closed successfully.")
	}

	slog.Info("Graceful shutdown complete.")
}
