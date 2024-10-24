CREATE TABLE IF NOT EXISTS users (
    id integer PRIMARY KEY,
    username text UNIQUE NOT NULL
);
