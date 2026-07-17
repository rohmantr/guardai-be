package middleware

import (
	"log/slog"
	"net/http"
	"time"
)

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func RequestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		next.ServeHTTP(rw, r)
		
		duration := time.Since(start)

		slog.Info("Request processed",
			slog.String("http_method", r.Method),
			slog.String("http_url", r.URL.String()),
			slog.Int("status_code", rw.statusCode),
			slog.Int64("duration_ms", duration.Milliseconds()),
			slog.String("client_ip", r.RemoteAddr),
		)
	})
}
