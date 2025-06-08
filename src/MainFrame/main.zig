const std = @import("std");
const heap = std.heap;

const MainFrame = @import("MainFrame.zig").MainFrame;

pub fn main() !void {
    var mf = MainFrame.init(heap.page_allocator);

    mf.run();
}
