const std = @import("std");
const zqlite = @import("zqlite");

pub const DB_PATH = "zgit.db";
pub const CONFIG_MAX_STRING_LENGTH = 256;
pub const REPO_NAME_MAX_LENGTH = 100; // same as github
pub const REPO_DESC_MAX_LENGTH = 128;
pub const EMAIL_MAX_LENGTH = 254; // https://stackoverflow.com/a/574698

pub fn init() !bool {
    const cwd = std.fs.cwd();

    var db_exists = true;
    cwd.access(DB_PATH, .{ .mode = .read_only }) catch {
        db_exists = false;
    };
    if (db_exists) {
        return false;
    }
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(DB_PATH, flags);
    defer conn.close();

    try conn.execNoArgs(@embedFile("./db_queries/create_table_users.sql"));

    const create_table_repo_sql = @embedFile("./db_queries/create_table_repo.sql");
    var repo_buf: [create_table_repo_sql.len + 64]u8 = undefined;
    try conn.execNoArgs(
        try std.fmt.bufPrintZ(
            &repo_buf,
            create_table_repo_sql,
            .{
                REPO_NAME_MAX_LENGTH,
                REPO_DESC_MAX_LENGTH,
            },
        ),
    );

    try conn.execNoArgs(@embedFile("./db_queries/create_table_user_repo_access.sql"));

    const create_table_config_sql = @embedFile("./db_queries/create_table_config.sql");
    var buf: [create_table_config_sql.len + 64]u8 = undefined;
    try conn.execNoArgs(
        try std.fmt.bufPrintZ(
            &buf,
            create_table_config_sql,
            .{ CONFIG_MAX_STRING_LENGTH, CONFIG_MAX_STRING_LENGTH },
        ),
    );
    // insert default config:
    try conn.execNoArgs("insert into config(id) values(0) on conflict do nothing;");

    // read current dir, insert repo records into db
    const dir = try cwd.openDir(".", .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    var iter = dir.iterate();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    while (try iter.next()) |entry| {
        if (entry.kind != .directory) {
            continue;
        }
        defer _ = arena.reset(.{ .retain_with_limit = 8192 });
        const result = try std.process.Child.run(.{
            .allocator = arena.allocator(),
            .cwd = entry.name,
            .argv = &.{
                "git",
                "rev-parse",
                "--is-bare-repository",
            },
        });
        if (std.mem.eql(u8, result.stdout, "true\n")) {
            std.debug.print("Found repo {s}\n", .{entry.name});
            try conn.exec(
                "insert into repo (name) values(?);",
                .{entry.name},
            );
        }
    }

    return true;
}

pub const Config = struct {
    site_name: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH) = .{},
    tagline: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH) = .{},
};

pub fn readConfig(config: *Config) !void {
    const flags = zqlite.OpenFlags.ReadOnly | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(DB_PATH, flags);
    defer conn.close();

    if (try conn.row("select site_name, tagline from config;", .{})) |row| {
        defer row.deinit();
        try config.site_name.appendSlice(row.text(0));
        try config.tagline.appendSlice(row.text(1));
        return;
    }

    unreachable; // config data not found in db
}

pub const Repo = struct {
    name: std.BoundedArray(u8, REPO_NAME_MAX_LENGTH) = .{},
    description: std.BoundedArray(u8, REPO_DESC_MAX_LENGTH) = .{},
    owner: std.BoundedArray(u8, EMAIL_MAX_LENGTH) = .{},
    last_committed: []const u8 = "",

    pub fn latestFirst(_: void, lhs: Repo, rhs: Repo) bool {
        return std.mem.order(
            u8,
            lhs.last_committed,
            rhs.last_committed,
        ).compare(std.math.CompareOperator.gt);
    }
};

pub fn listRepos(arena: std.mem.Allocator) !std.ArrayList(Repo) {
    var repos = std.ArrayList(Repo).init(arena);
    var conn = try zqlite.open(DB_PATH, zqlite.OpenFlags.ReadOnly | zqlite.OpenFlags.EXResCode);
    defer conn.close();

    var rows = try conn.rows("select name, description from repo order by name;", .{});
    defer rows.deinit();
    while (rows.next()) |row| {
        var repo = Repo{};
        try repo.name.appendSlice(row.text(0));
        try repo.description.appendSlice(row.text(1));

        const result = try std.process.Child.run(.{
            .allocator = arena,
            .cwd = repo.name.slice(),
            .argv = &.{
                "git",
                "log",
                "-1",
                "--format=%ai",
            },
        });
        if (result.stdout.len > 0) {
            repo.last_committed = result.stdout;
        }

        try repos.append(repo);
    }

    if (rows.err) |err| {
        return err;
    }
    return repos;
}

const Commit = struct {
    title: []const u8,
    hash_long: []const u8,
    hash_short: []const u8,
    author_name: []const u8,
    author_email: []const u8,
    datetime: []const u8,
};

const RepoDetail = struct {
    name: []const u8,
    description: []const u8,
    commits: []Commit,
};

pub fn getRepo(arena: std.mem.Allocator, name: []const u8) !RepoDetail {
    var conn = try zqlite.open(DB_PATH, zqlite.OpenFlags.ReadOnly | zqlite.OpenFlags.EXResCode);
    defer conn.close();

    const maybeRow = try conn.row("select description from repo where name=?;", .{name});
    if (maybeRow == null) {
        return error.RepoNotFound;
    }

    const row = maybeRow.?;
    defer row.deinit();

    const description = try arena.dupe(u8, row.text(0));

    const result = try std.process.Child.run(.{
        .allocator = arena,
        .cwd = name,
        .argv = &.{
            "git",
            "log",
            "--pretty=%H»¦«%h»¦«%s»¦«%aN»¦«%aE»¦«%ai",
        },
        .max_output_bytes = 1024 * 1024 * 100,
    });
    const git_log = result.stdout;

    var commits = std.ArrayList(Commit).init(arena);

    if (git_log.len > 0) {
        var line_iter = std.mem.splitSequence(u8, git_log, "\n");
        while (line_iter.next()) |line| {
            if (line.len == 0) {
                continue;
            }
            var iter = std.mem.splitSequence(u8, line, "»¦«");
            const commit = Commit{
                .hash_long = iter.next().?,
                .hash_short = iter.next().?,
                .title = iter.next().?,
                .author_name = iter.next().?,
                .author_email = iter.next().?,
                .datetime = iter.next().?,
            };
            try commits.append(commit);
        }
    }
    return .{
        .name = name,
        .description = description,
        .commits = commits.items,
    };
}
