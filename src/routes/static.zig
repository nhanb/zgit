const std = @import("std");
const httpz = @import("httpz");

pub const URL_PATH = "/static";
const FS_PATH = "./static";

// To add a new static asset:
// (0) Put the file in FS_PATH
// (1) Declare its properties in `raw_assets`
// (2) Define a public const for it from the generated `assets` var
//
// This setup is a bit janky but it's the least repetitive I could think of... without resorting
// to full-on zig source code generation, which would be severely hurt readability IMHO.

// (1)
const raw_assets = .{
    .{ "mascot.png", .{ .img = .{ .width = "90", .height = "120" } } },
    .{ "style.css", .css },
    .{ "home.css", .css },
    .{ "register.css", .css },
};

// (2)
pub const mascot_png = assets[0];
pub const style_css = assets[1];
pub const home_css = assets[2];
pub const register_css = assets[3];

pub const Asset = struct {
    name: []const u8,
    kind: union(enum) {
        img: struct {
            // these are used in <img width="xx" height="yy"> to avoid DOM shifting on page load.
            width: []const u8,
            height: []const u8,
        },
        css: void,
    },
    data: []const u8,
    url_path: []const u8,
};

const assets: []const Asset = assets_block: {
    var result: [raw_assets.len]Asset = undefined;
    for (raw_assets, 0..) |raw, i| {
        result[i] = .{
            .name = raw[0],
            .kind = raw[1],
            .data = @embedFile(FS_PATH ++ "/" ++ raw[0]),
            .url_path = URL_PATH ++ "/" ++ raw[0],
        };
    }
    // Copy to a const because result is a comptime var which is not allowed to "leak":
    // https://ziggit.dev/t/comptime-mutable-memory-changes/3702
    const final = result;
    break :assets_block &final;
};

pub fn serve(req: *httpz.Request, res: *httpz.Response) !void {
    const filename = req.param("filename").?;
    // TODO is there a better way than repeatedly running std.mem.eql?
    inline for (assets) |asset| {
        if (std.mem.eql(u8, filename, asset.name)) {
            res.status = 200;
            res.body = asset.data;
            return;
        }
    }
    res.status = 404;
}
