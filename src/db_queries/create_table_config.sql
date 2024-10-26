CREATE TABLE IF NOT EXISTS config (
    id integer PRIMARY KEY CHECK (id = 0), -- ensures single row
    site_name text NOT NULL CHECK (length(site_name) <= {d}) DEFAULT 'My personal git stash',
    tagline text NOT NULL CHECK (length(tagline) <= {d}) DEFAULT 'Powered by zgit'
);
