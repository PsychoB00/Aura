/// STD
const std = @import("std");
const Allocator = std.mem.Allocator;

/// Third Party
const zap = @import("zap");

pub const Endpoint = struct {
    /// Register any endpoint in EndpointSetT instance
    pub fn registerEndpointSet(AppT: type, app: *AppT, EndpointSetT: type, endpoint_set: *EndpointSetT) !void {
        // Check if EndpointSetT is struct
        const endpoint_set_info = @typeInfo(EndpointSetT);
        if (endpoint_set_info != .@"struct") @compileError("EndpointSetT must be struct");

        // Iterate through routing endpoint fields
        inline for (endpoint_set_info.@"struct".fields) |endpoint| {
            comptime AppT.Endpoint.checkEndpointType(endpoint.type);
            try app.register(&@field(endpoint_set, endpoint.name));
        }
    }
};
