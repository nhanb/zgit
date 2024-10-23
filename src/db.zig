const zqlite = @import("zqlite");

pub fn init(db_path: [:0]const u8) !void {
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(db_path, flags);
    defer conn.close();

    try conn.execNoArgs(@embedFile("./db_queries/create_table_users.sql"));
    try conn.execNoArgs(@embedFile("./db_queries/create_table_repos.sql"));
    try conn.execNoArgs(@embedFile("./db_queries/create_table_user_repo_access.sql"));
    try conn.execNoArgs(@embedFile("./db_queries/create_table_config.sql"));
    try conn.execNoArgs(@embedFile("./db_queries/insert_default_configs.sql"));
}
