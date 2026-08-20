package database

import (
	"database/sql"
	"embed"
	"fmt"
	"meerkat/config"
	"meerkat/logger"

	_ "github.com/go-sql-driver/mysql"
	"github.com/golang-migrate/migrate/v4"
	mysqlmigrate "github.com/golang-migrate/migrate/v4/database/mysql"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

// BuildDSN returns a MySQL DSN. When dbName is empty the DSN targets the server
// (no specific database), which is needed to CREATE DATABASE. multiStatements
// enables golang-migrate to run multi-statement migration files.
func BuildDSN(cfg *config.Config, dbName string, multiStatements bool) string {
	params := "charset=utf8mb4&collation=utf8mb4_general_ci&parseTime=True&loc=UTC"
	if multiStatements {
		params += "&multiStatements=true"
	}
	return fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?%s",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, dbName, params)
}

// EnsureDatabase creates the target database if it does not already exist.
func EnsureDatabase(cfg *config.Config) error {
	rootDSN := BuildDSN(cfg, "", false)
	rootDB, err := sql.Open("mysql", rootDSN)
	if err != nil {
		return fmt.Errorf("failed to open server connection: %w", err)
	}
	defer rootDB.Close()

	if err := rootDB.Ping(); err != nil {
		return fmt.Errorf("failed to connect to MySQL server at %s:%s: %w", cfg.DBHost, cfg.DBPort, err)
	}

	if _, err := rootDB.Exec(fmt.Sprintf(
		"CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci",
		cfg.DBName)); err != nil {
		return fmt.Errorf("failed to create database %q: %w", cfg.DBName, err)
	}
	return nil
}

// InitDB creates the database if needed, runs migrations and returns a GORM handle.
func InitDB(cfg *config.Config) (*gorm.DB, error) {
	// Make sure the target database exists before running migrations.
	if err := EnsureDatabase(cfg); err != nil {
		return nil, err
	}

	// Run migrations.
	appDSN := BuildDSN(cfg, cfg.DBName, true)
	sqlDB, err := sql.Open("mysql", appDSN)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}
	if err := RunMigrations(sqlDB); err != nil {
		return nil, fmt.Errorf("failed to run migrations: %w", err)
	}

	// Open the GORM connection (multiStatements not needed for the app).
	gormDSN := BuildDSN(cfg, cfg.DBName, false)
	db, err := gorm.Open(mysql.Open(gormDSN), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect with GORM: %w", err)
	}

	return db, nil
}

// newMigrator builds a golang-migrate instance backed by the embedded SQL files.
func newMigrator(db *sql.DB) (*migrate.Migrate, error) {
	driver, err := mysqlmigrate.WithInstance(db, &mysqlmigrate.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to create migration driver: %w", err)
	}

	sourceDriver, err := iofs.New(migrationsFS, "migrations")
	if err != nil {
		return nil, fmt.Errorf("failed to create migration source: %w", err)
	}

	m, err := migrate.NewWithInstance("iofs", sourceDriver, "mysql", driver)
	if err != nil {
		return nil, fmt.Errorf("failed to create migration instance: %w", err)
	}
	return m, nil
}

// RunMigrations applies all pending migrations to the given database.
func RunMigrations(db *sql.DB) error {
	m, err := newMigrator(db)
	if err != nil {
		return err
	}

	// Recover from a dirty state (e.g. a migration that failed halfway).
	version, dirty, err := m.Version()
	if err != nil && err != migrate.ErrNilVersion {
		return fmt.Errorf("failed to get migration version: %w", err)
	}
	if dirty {
		logger.Warn().Uint("version", version).Msg("Database is in dirty state, forcing version")
		if err := m.Force(int(version)); err != nil {
			return fmt.Errorf("failed to force version: %w", err)
		}
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to apply migrations: %w", err)
	}

	version, _, err = m.Version()
	if err != nil && err != migrate.ErrNilVersion {
		return fmt.Errorf("failed to get final version: %w", err)
	}
	if err == migrate.ErrNilVersion {
		logger.Info().Msg("No migrations applied (database is empty)")
	} else {
		logger.Info().Uint("version", version).Msg("Migrations applied successfully")
	}

	return nil
}

// RollbackLast rolls back the most recent migration (use with caution).
func RollbackLast(db *sql.DB) error {
	m, err := newMigrator(db)
	if err != nil {
		return err
	}
	if err := m.Steps(-1); err != nil {
		return fmt.Errorf("failed to rollback migration: %w", err)
	}
	logger.Info().Msg("Migration rolled back successfully")
	return nil
}

// MigrationVersion returns the current migration version (and dirty flag).
func MigrationVersion(db *sql.DB) (uint, bool, error) {
	m, err := newMigrator(db)
	if err != nil {
		return 0, false, err
	}
	version, dirty, err := m.Version()
	if err == migrate.ErrNilVersion {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return version, dirty, nil
}
