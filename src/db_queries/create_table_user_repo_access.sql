CREATE TABLE IF NOT EXISTS user_repo_access (
    user_id integer NOT NULL,
    repo_id integer NOT NULL,
    can_read boolean NOT NULL,
    can_write boolean NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (repo_id) REFERENCES repo (id)
);
