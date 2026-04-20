const std = @import("std");

pub fn build(b: *std.Build) void {
    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
        .optimize = .ReleaseSmall,
        .strip = true,
    });
    wasm_mod.export_symbol_names = &.{ "alloc", "free", "greet" };

    const wasm = b.addExecutable(.{
        .name = "zigflare",
        .root_module = wasm_mod,
    });
    wasm.entry = .disabled;

    const install = b.addInstallArtifact(wasm, .{});
    b.getInstallStep().dependOn(&install.step);

    // ── Native tests ──
    const test_mod = b.createModule(.{
        .root_source_file = b.path("greet.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    const tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
