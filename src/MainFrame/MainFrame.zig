/// STD
const std = @import("std");
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});
const Allocator = std.mem.Allocator;

/// Aura
const core = @import("core");

/// Third Party
const zap = @import("zap");
const Authenticator = zap.Auth.BearerSingle;

pub const MainFrame = struct {
    const Context = struct {
        bearer_token: []const u8,
    };
    const App = zap.App.Create(Context);
    const EndpointSet = struct {
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

        stop: StopEndpoint,

        pub fn init() EndpointSet {
            return .{
                .stop = StopEndpoint.init("/stop"),
            };
        }
    };

    allocator: Allocator,

    context: Context,
    app: App,
    endpoint_set: EndpointSet,

    /// Initialize MainFrame
    ///
    /// MUST CALL `deinit` to deinitialize
    pub fn init(self: *MainFrame, gpa: *GeneralPurpouseAllocator) !void {
        self.allocator = gpa.allocator();

        // Context
        self.context = .{
            .bearer_token = "ABCDEFG",
        };

        // Application
        self.app = try App.init(
            self.allocator,
            &self.context,
            .{},
        );

        // Routing
        self.endpoint_set = EndpointSet.init();

        // Register endpoints
        try core.Endpoint.registerEndpointSet(App, &self.app, EndpointSet, &self.endpoint_set);
    }

    /// Listens and starts `zap` Application
    pub fn run(self: *MainFrame) !void {
        // Listen
        try self.app.listen(.{
            .interface = "0.0.0.0",
            .port = 3000,
        });

        // Start
        zap.start(.{
            .threads = 2,
            .workers = 1,
        });
    }

    /// Deinitialize MainFrame
    pub fn deinit(self: *MainFrame) void {
        self.app.deinit();
    }
};
