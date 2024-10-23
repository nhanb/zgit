CREATE TABLE repo (
    id integer PRIMARY KEY,
    name text UNIQUE NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP,
    created_by integer NOT NULL,
    FOREIGN KEY (created_by) REFERENCES users (id)
);
