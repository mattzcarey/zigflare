/// Zigflare — WASM entry point. Exports alloc, free, greet.
const std = @import("std");
const greet_mod = @import("greet.zig");

const allocator = std.heap.wasm_allocator;

export fn alloc(len: u32) ?[*]u8 {
    const buf = allocator.alloc(u8, len) catch return null;
    return buf.ptr;
}

export fn free(ptr: [*]u8, len: u32) void {
    allocator.free(ptr[0..len]);
}

export fn greet(name_ptr: [*]const u8, name_len: u32, out_ptr: [*]u8, out_cap: u32) u32 {
    return greet_mod.doGreet(allocator, name_ptr[0..name_len], out_ptr[0..out_cap]);
}
