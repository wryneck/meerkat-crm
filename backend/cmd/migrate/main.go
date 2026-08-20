package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/go-sql-driver/mysql"

	"meerkat/config"
	"meerkat/database"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Usage: go run cmd/migrate/main.go [up|down|version]")
	}

	command := os.Args[1]

	// Load database configuration from the environment (same defaults as the app).
	cfg := config.LoadConfig()

	// The target database must exist before migrations can run.
	if err := database.EnsureDatabase(cfg); err != nil {
		log.Fatalf("Failed to ensure database exists: %v", err)
	}

	dsn := database.BuildDSN(cfg, cfg.DBName, true)
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
	defer db.Close()

	// Execute command
	switch command {
	case "up":
		if err := database.RunMigrations(db); err != nil {
			log.Fatalf("Failed to run migrations: %v", err)
		}
		fmt.Println("Migrations applied successfully!")
	case "down":
		if err := database.RollbackLast(db); err != nil {
			log.Fatalf("Failed to rollback migrations: %v", err)
		}
		fmt.Println("Migrations rolled back successfully!")
	case "version":
		version, dirty, err := database.MigrationVersion(db)
		if err != nil {
			log.Fatalf("Failed to get migration version: %v", err)
		}
		if version == 0 {
			fmt.Println("No migrations applied yet")
		} else {
			fmt.Printf("Current version: %d (dirty: %v)\n", version, dirty)
		}
	default:
		log.Fatalf("Unknown command: %s. Use 'up', 'down', or 'version'", command)
	}
}
