const std = @import("std");
const zqlite = @import("zqlite");

pub const DB_PATH = "workdir/zgit.db";
pub const CONFIG_MAX_STRING_LENGTH = 256;

pub fn init() !void {
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(DB_PATH, flags);
    defer conn.close();

    try conn.execNoArgs(@embedFile("./db_queries/create_table_users.sql"));
    try conn.execNoArgs(@embedFile("./db_queries/create_table_repos.sql"));
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
    try conn.execNoArgs("insert into config(id) values(0);"); // insert default config
}

pub const Config = struct {
    title: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH),
    tagline: std.BoundedArray(u8, CONFIG_MAX_STRING_LENGTH),
};

pub fn readConfig(config: *Config) !void {
    const flags = zqlite.OpenFlags.ReadOnly | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(DB_PATH, flags);
    defer conn.close();

    if (try conn.row("select title, tagline from config;", .{})) |row| {
        defer row.deinit();
        try config.title.appendSlice(row.text(0));
        try config.tagline.appendSlice(row.text(1));
        return;
    }

    unreachable; // config data not found in db
}
