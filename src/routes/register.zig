const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    const arena = res.arena;
    const h = html.Builder{ .allocator = arena };
    const body = templates.base(
        arena,
        "Register",
        h.div(null, .{
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
    );

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
