CREATE TABLE IF NOT EXISTS repo (
    id integer PRIMARY KEY,
    name text UNIQUE NOT NULL CHECK (length(name) <= {}),
    description text NOT NULL CHECK (length(name) <= {}) DEFAULT '',
    owner integer DEFAULT NULL,
    FOREIGN KEY (owner) REFERENCES users (id)
);
