/// Core logic — pure, no WASM dependencies, testable natively.
const std = @import("std");

pub fn doGreet(a: std.mem.Allocator, name: []const u8, out: []u8) u32 {
    const greeting = std.fmt.allocPrint(a, "Hello, {s}!", .{name}) catch return 0;
    defer a.free(greeting);
    if (greeting.len > out.len) return 0;
    @memcpy(out[0..greeting.len], greeting);
    return @intCast(greeting.len);
}

// ── Tests ───────────────────────────────────────────────────────────────────

const testing = std.testing;

test "greet basic" {
    var buf: [64]u8 = undefined;
    const len = doGreet(testing.allocator, "Zig", &buf);
    try testing.expectEqualStrings("Hello, Zig!", buf[0..len]);
}

test "greet empty name" {
    var buf: [64]u8 = undefined;
    const len = doGreet(testing.allocator, "", &buf);
    try testing.expectEqualStrings("Hello, !", buf[0..len]);
}

test "greet unicode" {
    var buf: [64]u8 = undefined;
    const len = doGreet(testing.allocator, "世界", &buf);
    try testing.expectEqualStrings("Hello, 世界!", buf[0..len]);
}

test "greet output too small" {
    var buf: [5]u8 = undefined;
    const len = doGreet(testing.allocator, "this won't fit", &buf);
    try testing.expectEqual(@as(u32, 0), len);
}

test "greet exact fit" {
    const expected = "Hello, AB!";
    var buf: [expected.len]u8 = undefined;
    const len = doGreet(testing.allocator, "AB", &buf);
    try testing.expectEqualStrings(expected, buf[0..len]);
}
