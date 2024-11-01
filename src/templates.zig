const std = @import("std");
const httpz = @import("httpz");
const html = @import("./html.zig");
const static = @import("./routes/static.zig");

pub const TemplateArgs = struct {
    builder: html.Builder,
    title_tag_text: []const u8,
    title: html.Child,
    subtitle: []const u8,
    main: html.Element,
};

pub fn base(args: TemplateArgs) html.Element {
    const h = args.builder;
    return h.html(
        .{ .lang = "en" },
        .{
            h.head(null, .{
                h.meta(.{ .charset = "utf-8" }),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
                h.title(null, .{ args.title_tag_text, " | zgit" }),
                h.link(.{ .rel = "stylesheet", .href = static.style_css.url_path }),
                h.link(.{ .rel = "icon", .type = "image/png", .href = static.developers_png.url_path }),
            }),
            h.body(null, .{
                h.header(null, .{
                    h.a(.{ .id = "home-link", .href = "/", .title = "Go to homepage" }, .{
                        h.img(.{
                            .id = "mascot",
                            .src = static.developers_png.url_path,
                            .width = static.developers_png.kind.img.width,
                            .height = static.developers_png.kind.img.height,
                        }),
                    }),
                    h.div(.{ .id = "title-container" }, .{
                        h.h1(.{ .id = "title" }, .{args.title}),
                        h.p(.{ .id = "subtitle" }, .{args.subtitle}),
                    }),
                }),
                args.main,
            }),
        },
    );
}
