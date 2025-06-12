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
const UsersAuthenticator = zap.Auth.Basic(std.StringHashMap([]const u8), .UserPass);

/// Main server of Aura eco-system
pub const MainFrame = struct {
    pub const Context = struct {
        users: *std.StringHashMap([]const u8),
        users_authenticator: UsersAuthenticator,

        /// Initialize Context
        ///
        /// MUST CALL `deinit` to deinitialize
        fn init(a: Allocator) !Context {
            const users = try a.create(std.StringHashMap([]const u8));
            users.* = std.StringHashMap([]const u8).init(a);
            // Mock users
            try users.put("mr_admin", "VeryUnsafe");
            try users.put("joe", "SomeGuy123");

            return .{
                .users = users,
                .users_authenticator = try UsersAuthenticator.init(a, users, null),
            };
        }

        /// Any unhandeled request will end up here
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

        /// Deinitialize Context
        fn deinit(self: *Context, a: Allocator) void {
            self.users_authenticator.deinit();
            self.users.deinit();
            a.destroy(self.users);
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
        self.context = try Context.init(self.allocator);

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
        self.context.deinit(self.allocator);
    }
};
