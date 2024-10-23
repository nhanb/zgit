CREATE TABLE config (
    name text PRIMARY KEY CHECK (name IN ('title', 'tagline')),
    value text
);
