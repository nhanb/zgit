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

    // TODO: read current dir, insert repo records into db
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
    last_commit_ts: u64 = 0,
};

pub fn listRepos(arena: std.mem.Allocator, repos: *std.ArrayList(Repo)) !void {
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
                "--no-pager",
                "log",
                "-1",
                "--format=%at",
            },
        });
        const ts = result.stdout;
        if (ts.len > 0) {
            repo.last_commit_ts = try std.fmt.parseUnsigned(u64, ts[0 .. ts.len - 1], 10);
        }

        try repos.append(repo);
    }

    if (rows.err) |err| {
        return err;
    }
}
