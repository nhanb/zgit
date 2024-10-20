const std = @import("std");
const httpz = @import("httpz");
const zqlite = @import("zqlite");
const html = @import("./html.zig");

const DB_PATH = "workdir/zgit.db";
const PORT = 8000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try initDb(DB_PATH);
    std.debug.print("Initialized {s}\n", .{DB_PATH});

    // More advance cases will use a custom "Handler" instead of "void".
    // The last parameter is our handler instance, since we have a "void"
    // handler, we passed a void ({}) value.
    var server = try httpz.Server(void).init(allocator, .{ .port = PORT }, {});
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }

    var router = server.router(.{});
    router.get("/register", handleRegister, .{});
    router.get("/static/style.css", handleStyleCss, .{});
    router.get("/static/register.css", handleRegisterCss, .{});
    std.debug.print("Started server at port {d}\n", .{PORT});

    // blocks
    try server.listen();
}

fn handleStyleCss(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("static/style.css");
}

fn handleRegisterCss(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("static/register.css");
}

fn handleRegister(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    const h = html.Builder{ .allocator = res.arena };
    const body = h.html(
        .{ .lang = "en" },
        .{
            h.head(null, .{
                h.title(null, .{"Register | zgit"}),
                h.link(.{ .rel = "stylesheet", .href = "/static/style.css" }),
                h.link(.{ .rel = "stylesheet", .href = "/static/register.css" }),
            }),
            h.body(null, .{
                h.h1(null, .{"Register"}),
                h.form(
                    .{ .style = "max-width: 30rem" },
                    .{
                        h.label(
                            .{ .@"for" = "username" },
                            .{"Username:"},
                        ),
                        h.input(
                            .{
                                .type = "text",
                                .id = "username",
                                .name = "username",
                                .required = "",
                            },
                        ),
                        h.label(
                            .{ .@"for" = "password" },
                            .{"Password:"},
                        ),
                        h.input(
                            .{
                                .type = "text",
                                .id = "password",
                                .name = "password",
                                .required = "",
                            },
                        ),
                        h.input(
                            .{
                                .type = "submit",
                                .value = "Register",
                            },
                        ),
                    },
                ),
            }),
        },
    );

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}

fn initDb(db_path: [:0]const u8) !void {
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(db_path, flags);
    defer conn.close();

    try conn.execNoArgs(
        \\create table users (
        \\    id integer primary key,
        \\    username text unique not null
        \\);
    );

    try conn.execNoArgs(
        \\create table repo (
        \\    id integer primary key,
        \\    name text unique not null,
        \\    created_at text default current_timestamp,
        \\    created_by integer not null,
        \\
        \\    foreign key (created_by) references users (id)
        \\);
    );

    try conn.execNoArgs(
        \\create table user_repo_access (
        \\    user_id integer not null,
        \\    repo_id integer not null,
        \\    can_read boolean not null,
        \\    can_write boolean not null,
        \\
        \\    foreign key (user_id) references users (id),
        \\    foreign key (repo_id) references repo (id)
        \\);
    );
}
