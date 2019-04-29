extern crate postgres;

use postgres::{Connection, TlsMode};
use postgres::tls::native_tls::NativeTls;

fn _sql_execute_scalar(connection: &Connection, sql_statement: &str) -> String {
    for row in &connection.query(sql_statement, &[]).unwrap() {
        return row.get(0);
    }
    panic!("scalar didn't return a value");
}

fn sql_execute_scalar(url: &str, use_tls: bool, sql_statement: &str) -> String {
    if use_tls {
        let negotiator = NativeTls::new().unwrap();
        let connection = Connection::connect(url, TlsMode::Require(&negotiator)).unwrap();
        return _sql_execute_scalar(&connection, sql_statement);
    } else {
        let connection = Connection::connect(url, TlsMode::None).unwrap();
        return _sql_execute_scalar(&connection, sql_statement);
    }
}

fn main() {
    let url = "postgres://postgres:postgres@postgresql.example.com:5432/postgres";

    println!("PostgreSQL Version:");
    println!("{}", sql_execute_scalar(url, false, "select version()"));

    println!("PostgreSQL Version:");
    println!("{}", sql_execute_scalar(url, false, "show server_version"));

    println!("PostgreSQL User Name (postgres; username/password credentials; non-encrypted TCP/IP connection):");
    println!("{}", sql_execute_scalar(url, false, "select current_user"));

    println!("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; non-encrypted TCP/IP connection):");
    println!("{}", sql_execute_scalar(url, false, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"));

    println!("Is this PostgreSQL connection encrypted? (postgres; username/password credentials; encrypted TCP/IP connection):");
    println!("{}", sql_execute_scalar(url, true, "select case when ssl then concat('YES (', version, ')') else 'NO' end as ssl from pg_stat_ssl where pid=pg_backend_pid()"));
}
