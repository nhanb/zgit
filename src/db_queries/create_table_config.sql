CREATE TABLE config (
    id integer PRIMARY KEY CHECK (id = 0), -- ensures single row
    title text NOT NULL CHECK (length(title) <= {d}) DEFAULT 'My personal git stash',
    tagline text NOT NULL CHECK (length(tagline) <= {d}) DEFAULT 'Powered by zgit'
);
