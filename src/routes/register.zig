const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");
const static = @import("./static.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    const arena = res.arena;
    const h = html.Builder{ .allocator = arena };
    const body = templates.base(.{
        .builder = h,
        .title = "Register",
        .subtitle = "Register your account here",
        .main = h.div(null, .{
            h.link(.{ .rel = "stylesheet", .href = static.register_css.url_path }),
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
    });

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
