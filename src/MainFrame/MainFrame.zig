const std = @import("std");
const mem = std.mem;

pub const MainFrame = struct {
    allocator: mem.Allocator,

    pub fn init(allocator: mem.Allocator) MainFrame {
        return MainFrame{
            .allocator = allocator,
        };
    }

    pub fn run(self: *MainFrame) void {
        _ = self;

        std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    }
};
