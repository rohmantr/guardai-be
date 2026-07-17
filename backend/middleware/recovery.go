package middleware

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"runtime/debug"
)

func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				stack := debug.Stack()
				slog.Error("Recovery caught panic",
					slog.Any("error", err),
					slog.String("stack", string(stack)),
					slog.String("http_method", r.Method),
					slog.String("http_url", r.URL.String()),
				)

				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				_ = json.NewEncoder(w).Encode(map[string]interface{}{
					"status":  "error",
					"message": "Internal Server Error",
				})
			}
		}()
		next.ServeHTTP(w, r)
	})
}
