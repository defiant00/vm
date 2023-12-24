const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // build

    const asm_exe = b.addExecutable(.{
        .name = "asm",
        .root_source_file = .{ .path = "src/asm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const dasm_exe = b.addExecutable(.{
        .name = "dasm",
        .root_source_file = .{ .path = "src/dasm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const vm_exe = b.addExecutable(.{
        .name = "vm",
        .root_source_file = .{ .path = "src/vm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(asm_exe);
    b.installArtifact(dasm_exe);
    b.installArtifact(vm_exe);

    const shared = b.addModule("shared", .{
        .source_file = .{ .path = "src/shared/shared.zig" },
    });

    asm_exe.addModule("shared", shared);
    dasm_exe.addModule("shared", shared);
    vm_exe.addModule("shared", shared);

    const asm_run_cmd = b.addRunArtifact(asm_exe);
    const dasm_run_cmd = b.addRunArtifact(dasm_exe);
    const vm_run_cmd = b.addRunArtifact(vm_exe);

    asm_run_cmd.step.dependOn(b.getInstallStep());
    dasm_run_cmd.step.dependOn(b.getInstallStep());
    vm_run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        asm_run_cmd.addArgs(args);
        dasm_run_cmd.addArgs(args);
        vm_run_cmd.addArgs(args);
    }

    const asm_run_step = b.step("asm", "Run the assembler");
    const dasm_run_step = b.step("dasm", "Run the disassembler");
    const vm_run_step = b.step("vm", "Run the VM");

    asm_run_step.dependOn(&asm_run_cmd.step);
    dasm_run_step.dependOn(&dasm_run_cmd.step);
    vm_run_step.dependOn(&vm_run_cmd.step);

    // test

    const asm_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/asm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const dasm_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/dasm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const vm_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/vm/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const asm_run_unit_tests = b.addRunArtifact(asm_unit_tests);
    const dasm_run_unit_tests = b.addRunArtifact(dasm_unit_tests);
    const vm_run_unit_tests = b.addRunArtifact(vm_unit_tests);

    const asm_test_step = b.step("test-asm", "Run assembler unit tests");
    const dasm_test_step = b.step("test-dasm", "Run disassembler unit tests");
    const vm_test_step = b.step("test-vm", "Run VM unit tests");

    asm_test_step.dependOn(&asm_run_unit_tests.step);
    dasm_test_step.dependOn(&dasm_run_unit_tests.step);
    vm_test_step.dependOn(&vm_run_unit_tests.step);
}
