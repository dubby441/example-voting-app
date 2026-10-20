#!/usr/bin/env python3
from pathlib import Path

worker = Path("worker/Program.cs")
result = Path("result/server.js")
if not worker.exists() or not result.exists():
    raise SystemExit("Run from the repository root.")

s = worker.read_text()
old = 'var pgsql = OpenDbConnection("Server=db;Username=postgres;Password=postgres;");'
new = 'var pgsql = OpenDbConnection(BuildDbConnectionString());'
if old in s:
    s = s.replace(old, new, 1)
elif new not in s:
    raise SystemExit("Could not find the initial database connection in worker/Program.cs.")
old = 'pgsql = OpenDbConnection("Server=db;Username=postgres;Password=postgres;");'
if old in s:
    s = s.replace(old, 'pgsql = OpenDbConnection(BuildDbConnectionString());', 1)
if "private static string BuildDbConnectionString()" not in s:
    marker = "        private static NpgsqlConnection OpenDbConnection(string connectionString)"
    helper = """        private static string BuildDbConnectionString()
        {
            var host = Environment.GetEnvironmentVariable("DB_HOST") ?? "db";
            var username = Environment.GetEnvironmentVariable("DB_USER") ?? "postgres";
            var password = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? "postgres";
            var database = Environment.GetEnvironmentVariable("DB_NAME") ?? "postgres";
            return $"Server={host};Username={username};Password={password};Database={database};";
        }

"""
    if marker not in s:
        raise SystemExit("Could not find OpenDbConnection method in worker/Program.cs.")
    s = s.replace(marker, helper + marker, 1)
worker.write_text(s)

s = result.read_text()
old = """var pool = new Pool({
  connectionString: 'postgres://postgres:postgres@db/postgres'
});"""
new = """var pool = new Pool({
  host: process.env.PGHOST || 'db',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'postgres',
  database: process.env.PGDATABASE || 'postgres'
});"""
if old in s:
    s = s.replace(old, new, 1)
elif "password: process.env.PGPASSWORD" not in s:
    raise SystemExit("Could not find database pool config in result/server.js.")
result.write_text(s)
print("Updated worker and result to use environment variables for database credentials.")
