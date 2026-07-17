package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestPrometheusMetrics(t *testing.T) {
	mux := http.NewServeMux()
	mux.HandleFunc("/test-metrics", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	handler := PrometheusMetrics(mux)
	server := httptest.NewServer(handler)
	defer server.Close()

	resp, err := http.Get(server.URL + "/test-metrics")
	if err != nil {
		t.Fatalf("failed to make request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("expected status 200, got %d", resp.StatusCode)
	}
}
