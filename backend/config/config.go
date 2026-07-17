package config

import (
	"os"
)

type Config struct {
	DatabaseURL string
	Port        string
	LogLevel    string
	RPCURL      string
}

func LoadConfig() *Config {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgresql://dev:dev@localhost:5432/rugradar_dev"
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = "info"
	}

	rpcURL := os.Getenv("RPC_URL")
	if rpcURL == "" {
		rpcURL = "https://sepolia.base.org"
	}

	return &Config{
		DatabaseURL: dbURL,
		Port:        port,
		LogLevel:    logLevel,
		RPCURL:      rpcURL,
	}
}
