extern crate native_tls;
extern crate postgres;

use native_tls::TlsConnector;
use postgres_native_tls::MakeTlsConnector;
use postgres::{Client, NoTls};

fn _sql_execute_scalar(client: &mut Client, sql_statement: &str) -> String {
    for row in client.query(sql_statement, &[]).unwrap() {
        return row.get(0);
    }
    panic!("scalar didn't return a value");
}

fn sql_execute_scalar(url: &str, use_tls: bool, sql_statement: &str) -> String {
    if use_tls {
        let connector = TlsConnector::new().unwrap();
        let connector = MakeTlsConnector::new(connector);
        let mut client = Client::connect(url, connector).unwrap();
        return _sql_execute_scalar(&mut client, sql_statement);
    } else {
        let mut client = Client::connect(url, NoTls).unwrap();
        return _sql_execute_scalar(&mut client, sql_statement);
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
