/// STD
const std = @import("std");
const GeneralPurpouseAllocator = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
});
const Allocator = std.mem.Allocator;

/// Third Party
const zap = @import("zap");
const Authenticator = zap.Auth.BearerSingle;

pub const MainFrame = struct {
    const Context = struct {
        bearer_token: []const u8,
    };

    const HTTP_RESPONSE_TEMPLATE: []const u8 =
        \\ <html><body>
        \\   {s} from ZAP on {s} (token {s} == {s} : {s})!!!
        \\ </body></html>
        \\
    ;

    const TestEndpoint = struct {
        path: []const u8,
        error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

        fn get_bearer_token(r: zap.Request) []const u8 {
            const auth_header = zap.Auth.extractAuthHeader(.Bearer, &r) orelse "Bearer (no token)";
            return auth_header[zap.Auth.AuthScheme.Bearer.str().len..];
        }

        pub fn get(ep: *TestEndpoint, arena: Allocator, context: *Context, r: zap.Request) !void {
            const used_token = get_bearer_token(r);
            const response = try std.fmt.allocPrint(
                arena,
                HTTP_RESPONSE_TEMPLATE,
                .{ "Hello", ep.path, used_token, context.bearer_token, "OK" },
            );
            r.setStatus(.ok);
            try r.sendBody(response);
        }

        pub fn unauthorized(ep: *TestEndpoint, arena: Allocator, context: *Context, r: zap.Request) !void {
            r.setStatus(.unauthorized);
            const used_token = get_bearer_token(r);
            const response = try std.fmt.allocPrint(
                arena,
                HTTP_RESPONSE_TEMPLATE,
                .{ "UNAUTHORIZED", ep.path, used_token, context.bearer_token, "NOT OK" },
            );
            try r.sendBody(response);
        }

        pub fn post(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn put(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn delete(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn patch(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn options(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
        pub fn head(_: *TestEndpoint, _: Allocator, _: *Context, _: zap.Request) !void {}
    };

    /// `zap` Application type used by MainFrame
    const App = zap.App.Create(Context);

    /// Authenticated Endpoint type
    const AuthEndpoint = App.Endpoint.Authenticating(TestEndpoint, Authenticator);

    allocator: Allocator,

    context: Context,
    app: App,
    authenticator: Authenticator,

    test_endpoint: TestEndpoint,
    auth_ep: AuthEndpoint,

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
        self.authenticator = try Authenticator.init(
            self.allocator,
            self.context.bearer_token,
            null,
        );

        // Endpoints
        self.test_endpoint = .{
            .path = "/test",
        };
        self.auth_ep = AuthEndpoint.init(&self.test_endpoint, &self.authenticator);
        try self.app.register(&self.auth_ep);
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
        self.authenticator.deinit();
        self.app.deinit();
    }
};
