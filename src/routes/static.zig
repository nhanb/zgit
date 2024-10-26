const httpz = @import("httpz");

pub fn serveMascotPng(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    res.body = @embedFile("./static/mascot.png");
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
