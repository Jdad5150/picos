const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "pico_controller",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/main.zig"),
    });

    mb.install_firmware(firmware, .{}); // .uf2
    mb.install_firmware(firmware, .{ .format = .elf }); // .elf

    // Controller 1
    const controller1 = mb.add_firmware(.{
        .name = "controller1",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/controller1.zig"),
    });

    mb.install_firmware(controller1, .{}); // .uf2
    mb.install_firmware(controller1, .{ .format = .elf }); // .elf
    
    const controller2 = mb.add_firmware(.{
        .name = "controller2",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/controller2.zig"),
    });

    mb.install_firmware(controller2, .{}); // .uf2
    mb.install_firmware(controller2, .{ .format = .elf }); // .elf

    // To add controller2 and controller3, duplicate the block above and change:
    //   .name = "controller2" (or "controller3")
    //   .root_source_file = b.path("src/controller2.zig") (or "controller3.zig")
    //
    // Example:
    // const controller2 = mb.add_firmware(.{
    //     .name = "controller2",
    //     .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
    //     .optimize = .ReleaseSmall,
    //     .root_source_file = b.path("src/controller2.zig"),
    // });
    // mb.install_firmware(controller2, .{}); // .uf2
    // mb.install_firmware(controller2, .{ .format = .elf }); // .elf
}
