const httpz = @import("httpz");
const html = @import("../html.zig");
const templates = @import("../templates.zig");

pub fn serve(_: *httpz.Request, res: *httpz.Response) !void {
    const arena = res.arena;
    res.status = 200;

    const h = html.Builder{ .allocator = arena };
    const body = templates.base(
        arena,
        "Home",
        h.div(null, .{
            h.h1(null, .{"Home"}),
            h.p(null, .{"Welcome to zgit!"}),
        }),
    );

    const writer = res.writer();
    try h.writeDoctype(writer);
    try body.writeTo(writer);
}
