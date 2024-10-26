const std = @import("std");
const zqlite = @import("zqlite");

pub const DB_PATH = "../zgit.db"; // big-ass TODO
pub const CONFIG_MAX_STRING_LENGTH = 256;
pub const REPO_NAME_MAX_LENGTH = 100; // same as github
pub const REPO_DESC_MAX_LENGTH = 128;
pub const EMAIL_MAX_LENGTH = 254; // https://stackoverflow.com/a/574698

pub fn init() !void {
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
}

pub const Config = struct {
    site_name: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH),
    tagline: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH),
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
    name: std.BoundedArray(u8, REPO_NAME_MAX_LENGTH),
    description: std.BoundedArray(u8, REPO_DESC_MAX_LENGTH),
    owner: std.BoundedArray(u8, EMAIL_MAX_LENGTH),
};

pub fn listRepos(repos: *std.ArrayList(Repo)) !void {
    var conn = try zqlite.open(DB_PATH, zqlite.OpenFlags.ReadOnly | zqlite.OpenFlags.EXResCode);
    defer conn.close();

    const rows = try conn.rows("select name, description from repo;", .{});
    defer rows.deinit();
    while (rows.next()) |row| {
        var repo: Repo = undefined;
        try repo.name.appendSlice(row.text(0));
        try repo.description.appendSlice(row.text(1));
        try repos.append(repo);
    }
    if (rows.err) |err| return err;
}
