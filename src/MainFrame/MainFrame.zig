/// STD
const std = @import("std");
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});
const Allocator = std.mem.Allocator;

/// Aura
const core = @import("core");
const EndpointSet = @import("EndpointSet.zig").EndpointSet;

/// Third Party
const zap = @import("zap");
const Authenticator = zap.Auth.BearerSingle;

/// Main server of Aura eco-system
pub const MainFrame = struct {
    pub const Context = struct {
        bearer_token: []const u8,

        pub fn unhandledRequest(_: *Context, _: Allocator, r: zap.Request) anyerror!void {
            if (r.path) |path| {
                if (path.len == 1) {
                    // redirect to login
                    try r.redirectTo("/login", null);
                    return;
                }
            }
            r.setStatus(.not_found);
        }
    };

    const App = zap.App.Create(Context);

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
