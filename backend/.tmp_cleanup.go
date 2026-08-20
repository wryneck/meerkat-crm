package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

func main() {
	dsn := fmt.Sprintf("root:%s@tcp(%s:3306)/meerkat?charset=utf8mb4&parseTime=True",
		os.Getenv("DB_PASSWORD"), os.Getenv("DB_HOST"))
	db, err := sql.Open("mysql", dsn)
	if err != nil { panic(err) }
	defer db.Close()

	// Delete test user (cascades to contacts, api_tokens, etc.)
	res, err := db.Exec("DELETE FROM users WHERE username = 'dbcheck'")
	if err != nil { panic(err) }
	n, _ := res.RowsAffected()
	fmt.Printf("Deleted test user: %d row(s)\n", n)

	// Safety: delete any orphaned test contact
	res, err = db.Exec("DELETE FROM contacts WHERE email = 'alice@test.local'")
	if err != nil { panic(err) }
	n, _ = res.RowsAffected()
	fmt.Printf("Deleted test contact: %d row(s)\n", n)

	// Show remaining row counts
	var users, contacts int
	db.QueryRow("SELECT COUNT(*) FROM users").Scan(&users)
	db.QueryRow("SELECT COUNT(*) FROM contacts").Scan(&contacts)
	fmt.Printf("Remaining: users=%d contacts=%d\n", users, contacts)
}
