const httpz = @import("httpz");

pub const Image = struct {
    width: []const u8,
    height: []const u8,
    data: []const u8,
};

pub const mascot_png = Image{
    .width = "90",
    .height = "120",
    .data = @embedFile("./static/mascot.png"),
};

pub fn serveMascotPng(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = mascot_png.data;
}

pub fn serveStyleCss(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("./static/style.css");
}

pub fn serveHomeCss(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("./static/home.css");
}

pub fn serveRegisterCss(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("./static/register.css");
}
