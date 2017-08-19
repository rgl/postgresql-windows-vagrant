package main

import (
	"database/sql"
	"fmt"
	"log"
	"strings"

	_ "github.com/lib/pq"
)

func sqlExecuteScalar(dataSourceName string, sqlStatement string) string {
	db, err := sql.Open("postgres", dataSourceName)
	if err != nil {
		log.Fatal("Open connection failed:", err.Error())
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatal("Ping failed:", err.Error())
	}

	var scalar string

	err = db.QueryRow(sqlStatement).Scan(&scalar)
	if err != nil {
		log.Fatal("Scan failed:", err.Error())
	}

	return scalar
}

// NB go uses the native windows Trusted Root Certification Authorities store to validate the server certificate.
func main() {
	dataSourceName := "host=pgsql.example.com port=5432 sslmode=disable user=postgres password=postgres dbname=postgres"
	dataSourceNameSsl := strings.Replace(dataSourceName, "sslmode=disable", "sslmode=verify-full", -1)

	fmt.Println("PostgreSQL Version:")
	fmt.Println(sqlExecuteScalar(dataSourceName, "select version()"))

	fmt.Println("PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):")
	fmt.Println(sqlExecuteScalar(dataSourceName, "select current_user"))

	fmt.Println("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):")
	fmt.Println(sqlExecuteScalar(dataSourceName, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"))

	fmt.Println("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; encrypted TCP/IP connection):")
	fmt.Println(sqlExecuteScalar(dataSourceNameSsl, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"))
}
