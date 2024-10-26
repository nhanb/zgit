const std = @import("std");
const httpz = @import("httpz");
const html = @import("./html.zig");

pub const TemplateArgs = struct {
    builder: html.Builder,
    title: []const u8,
    subtitle: []const u8,
    main: html.Element,
};

pub fn base(args: TemplateArgs) html.Element {
    const h = args.builder;
    return h.html(
        .{ .lang = "en" },
        .{
            h.head(null, .{
                h.title(null, .{ args.title, " | zgit" }),
                h.link(.{ .rel = "stylesheet", .href = "/static/style.css" }),
            }),
            h.body(null, .{
                h.header(null, .{
                    h.a(.{ .id = "home-link", .href = "/", .title = "Go to homepage" }, .{
                        h.img(.{ .id = "mascot", .src = "/static/mascot.png" }),
                    }),
                    h.div(.{ .id = "title-container" }, .{
                        h.h1(.{ .id = "title" }, .{args.title}),
                        h.p(.{ .id = "tagline" }, .{args.subtitle}),
                    }),
                }),
                args.main,
            }),
        },
    );
}
