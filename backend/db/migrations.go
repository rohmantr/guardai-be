package db

import (
	"context"
	"embed"
	"fmt"
	"io/fs"
	"log/slog"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed migrations/*.sql
var migrationFS embed.FS

func RunMigrations(ctx context.Context, pool *pgxpool.Pool) error {
	// 1. Create migrations tracking table if not exists
	_, err := pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS go_migrations (
			version VARCHAR(255) PRIMARY KEY,
			run_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create migration table: %w", err)
	}

	// 2. Fetch already executed migrations
	rows, err := pool.Query(ctx, "SELECT version FROM go_migrations")
	if err != nil {
		return fmt.Errorf("failed to fetch run migrations: %w", err)
	}
	defer rows.Close()

	runMigrations := make(map[string]bool)
	for rows.Next() {
		var version string
		if err := rows.Scan(&version); err != nil {
			return fmt.Errorf("failed to scan migration version: %w", err)
		}
		runMigrations[version] = true
	}

	// 3. Read embedded SQL files
	entries, err := fs.ReadDir(migrationFS, "migrations")
	if err != nil {
		return fmt.Errorf("failed to read migrations directory: %w", err)
	}

	// Sort files by name to ensure sequential execution
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Name() < entries[j].Name()
	})

	for _, entry := range entries {
		name := entry.Name()
		if !strings.HasSuffix(name, ".sql") {
			continue
		}

		if runMigrations[name] {
			slog.Debug("Migration already applied, skipping", slog.String("file", name))
			continue
		}

		slog.Info("Applying database migration", slog.String("file", name))

		content, err := fs.ReadFile(migrationFS, "migrations/"+name)
		if err != nil {
			return fmt.Errorf("failed to read migration file %s: %w", name, err)
		}

		// Run migration within a transaction
		tx, err := pool.Begin(ctx)
		if err != nil {
			return fmt.Errorf("failed to begin transaction: %w", err)
		}
		defer tx.Rollback(ctx)

		if _, err := tx.Exec(ctx, string(content)); err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", name, err)
		}

		if _, err := tx.Exec(ctx, "INSERT INTO go_migrations (version) VALUES ($1)", name); err != nil {
			return fmt.Errorf("failed to record migration status for %s: %w", name, err)
		}

		if err := tx.Commit(ctx); err != nil {
			return fmt.Errorf("failed to commit migration %s: %w", name, err)
		}

		slog.Info("Successfully applied database migration", slog.String("file", name))
	}

	return nil
}
