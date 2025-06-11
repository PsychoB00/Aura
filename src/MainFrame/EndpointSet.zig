/// STD
const std = @import("std");
const log = std.log;
const Allocator = std.mem.Allocator;

/// Aura
const Context = @import("MainFrame.zig").MainFrame.Context;
const login_page = @embedFile("pages/login.html");

/// Third Party
const zap = @import("zap");

/// EndpointSet used by MainFrame
pub const EndpointSet = struct {
    const LoginEndpoint = struct {
        path: []const u8,
        error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

        pub fn init(path: []const u8) LoginEndpoint {
            return .{
                .path = path,
            };
        }

        pub fn get(_: *LoginEndpoint, _: Allocator, _: *Context, r: zap.Request) !void {
            try r.sendBody(login_page);
        }

        pub fn post(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn put(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn delete(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn patch(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn options(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn head(_: *LoginEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    };

    const StopEndpoint = struct {
        path: []const u8,
        error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

        pub fn init(path: []const u8) StopEndpoint {
            return .{
                .path = path,
            };
        }

        pub fn get(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {
            zap.stop();
        }

        pub fn post(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn put(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn delete(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn patch(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn options(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn head(_: *StopEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    };

    login: LoginEndpoint,
    stop: StopEndpoint,

    pub fn init() EndpointSet {
        return .{
            .login = LoginEndpoint.init("/login"),
            .stop = StopEndpoint.init("/stop"),
        };
    }
};
