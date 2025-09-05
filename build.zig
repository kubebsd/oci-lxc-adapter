const std = @import("std");

pub fn build(b: *std.Build) void {
    const mode = b.standardReleaseOptions();

    // Створюємо виконуваний файл
    const exe = b.addExecutable("OCI2LXC", "src/main.zig");
    exe.setBuildMode(mode);
    exe.install();

    // Додаємо тестовий крок, вказуючи основний тестовий файл
    const test_step = b.addTest("src/main.zig");
    test_step.setBuildMode(mode);

    // Створюємо крок для запуску тестів
    const run_tests = b.addRunArtifact(test_step);

    // Основний крок build залежить від кроку запуску тестів
    const test_build_step = b.step("test", "Run unit tests");
    test_build_step.dependOn(&run_tests.step);
}
