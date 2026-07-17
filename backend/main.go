package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"guardai-be/config"
	"guardai-be/db"
	"guardai-be/middleware"
)

func main() {
	// 1. Load config
	cfg := config.LoadConfig()

	// 2. Set up slog JSON logger
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

	// 3. Initialize database connection pool
	slog.Info("Initializing database connection...")
	dbPool, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		slog.Error("Failed to initialize database", slog.Any("error", err))
		os.Exit(1)
	}
	defer dbPool.Close()
	slog.Info("Database connection pool initialized successfully.")

	// 4. Run migrations
	ctx := context.Background()
	slog.Info("Running database migrations...")
	if err := db.RunMigrations(ctx, dbPool); err != nil {
		slog.Error("Failed to run migrations", slog.Any("error", err))
		os.Exit(1)
	}
	slog.Info("Database migrations completed successfully.")

	// 5. Set up HTTP router & handlers
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

	// Wrap mux with middleware chain
	handler := middleware.Recovery(middleware.RequestLogger(mux))

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      handler,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	// 6. Start server in goroutine
	go func() {
		slog.Info("Starting HTTP server", slog.String("port", cfg.Port))
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("HTTP server failed", slog.Any("error", err))
			os.Exit(1)
		}
	}()

	// 7. Graceful Shutdown Signal Interception
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	<-stop
	slog.Warn("Received shutdown signal. Starting graceful shutdown...")

	// 8. Execute shutdown procedure with a 10s timeout
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("Error closing HTTP server", slog.Any("error", err))
	} else {
		slog.Info("HTTP server closed successfully.")
	}

	// dbPool.Close() is called via defer in main
	slog.Info("Graceful shutdown complete.")
}
