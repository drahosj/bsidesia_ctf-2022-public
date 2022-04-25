#!/bin/bash

set -e
set -u

echo "  Creating user and database confluence"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER confluence WITH PASSWORD 'UVaE5EUG9YgLAZQaA665DFEfjAJyoNNF';;
    CREATE DATABASE confluence;
    GRANT ALL PRIVILEGES ON DATABASE confluence TO confluence;
EOSQL

echo "  Creating user and database jira"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER jira WITH PASSWORD 'JeBxzHEdwWVU4fU96NMjhEZw5AWNBqRz';
    CREATE DATABASE jira;
    GRANT ALL PRIVILEGES ON DATABASE jira TO jira;
EOSQL


echo "  Creating database flag"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"  <<-EOSQL
    CREATE DATABASE flag;
EOSQL

# https://medium.com/@swaplord/grant-read-only-access-to-postgresql-a-database-for-a-user-35c57897dd0b
echo "  Creating permissions for database flag"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" flag <<-EOSQL
    GRANT CONNECT ON DATABASE flag TO jira;
    GRANT CONNECT ON DATABASE flag TO confluence;
    GRANT USAGE ON SCHEMA public TO jira;
    GRANT USAGE ON SCHEMA public TO confluence;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO jira;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO confluence;
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO jira;
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO confluence;
EOSQL


echo "  creating table and inserting flag into flag datase"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" flag <<-EOSQL
  CREATE TABLE flag (
      ID  SERIAL PRIMARY KEY,
      flag CHAR(45) NOT NULL
  );
  INSERT INTO flag (flag) VALUES ('SecDSM{a2dffc04-2621-4e0d-8192-0e115ffb142d}');
EOSQL



