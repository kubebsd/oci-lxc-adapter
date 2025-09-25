const std = @import("std");
const cli = @import("cli");

const ExitCode = enum(i32) {
    Success = 0,
    InvalidArgs = 1,
    UnknownCommand = 2,
    RuntimeError = 3,
};

const OutputFormat = enum {
    Plain,
    Json,
};

var verbose: bool = false;
var outputFormat: OutputFormat = OutputFormat.Plain;

// Простий список контейнерів для демонстрації
var containers = [_][]const u8{"alpha", "beta", "gamma"};
var runningContainers = std.AutoHashMap([]const u8, bool).init(std.heap.page_allocator);

fn verboseLog(comptime fmt: []const u8, args: anytype) void {
    if (verbose) {
        const stderr = std.io.getStdErr().writer();
        _ = stderr.print("[DEBUG] ", .{});
        _ = stderr.print(fmt, args);
        _ = stderr.print("\n", .{});
    }
}

fn printHelp() void {
    const stdout = std.io.getStdOut().writer();
    _ = stdout.print(
        "Usage: oci-lxc-adapter <command> [options]\n\n" ++
        "Commands:\n" ++
        "  run     Start a container\n" ++
        "  status  Show container status\n" ++
        "  stop    Stop a container\n" ++
        "  list    List all containers\n" ++
        "  help    Show this help message\n\n" ++
        "Options:\n" ++
        "  -v, --verbose    Enable verbose logging\n" ++
        "  --json           Output in JSON format\n" ++
        "  -h, --help       Show help\n",
    .{});
}

fn outputResult(fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    switch (outputFormat) {
        .Plain => _ = stdout.print(fmt, args),
        .Json => _ = stdout.print(fmt, args), // тут припускаємо що форматований рядок це JSON, якщо потрібно
    }
    _ = stdout.print("\n", .{});
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var args_it = std.process.argsIterator();

    // Пропускаємо ім'я програми
    _ = args_it.next();

    // Якщо немає команди — показати допомогу
    const maybe_command = args_it.next();
    if (maybe_command == null) {
        printHelp();
        std.os.exit(ExitCode.InvalidArgs);
    }

    const command = maybe_command.?;
    // Парсимо додаткові опції
    var args = std.ArrayList([]const u8).init(allocator);
    while (true) {
        const arg = args_it.next();
        if (arg == null) break;
        _ = args.append(arg.?);
    }

    // Визначаємо глобальні опції
    verbose = args.contains("--verbose") or args.contains("-v");
    outputFormat = if (args.contains("--json")) OutputFormat.Json else OutputFormat.Plain;
    if (args.contains("-h") or args.contains("--help")) {
        printHelp();
        std.os.exit(ExitCode.Success);
    }

    switch (command) {
        "run" => runCommand(&args),
        "status" => statusCommand(&args),
        "stop" => stopCommand(&args),
        "list" => listCommand(),
        "help" => {
            printHelp();
            std.os.exit(ExitCode.Success);
        },
        else => {
            const stderr = std.io.getStdErr().writer();
            _ = stderr.print("Error: Unknown command '{s}'\n", .{command});
            std.os.exit(ExitCode.UnknownCommand);
        },
    }
}

fn runCommand(args: *std.ArrayList([]const u8)) void {
    if (args.len < 1) {
        printHelp();
        std.os.exit(ExitCode.InvalidArgs);
    }
    const containerName = args.items[0];
    verboseLog("Running container: {s}", .{containerName});
    const _ = runningContainers.put(containerName, true);

    if (outputFormat == OutputFormat.Json) {
        outputResult("{\"container\": \"{s}\", \"status\": \"running\"}", .{containerName});
    } else {
        outputResult("Container '{s}' started.", .{containerName});
    }
    std.os.exit(ExitCode.Success);
}

fn statusCommand(args: *std.ArrayList([]const u8)) void {
    if (args.len < 1) {
        printHelp();
        std.os.exit(ExitCode.InvalidArgs);
    }
    const containerName = args.items[0];
    verboseLog("Getting status for container: {s}", .{containerName});
    const isRunning = runningContainers.get(containerName) orelse false;

    if (outputFormat == OutputFormat.Json) {
        outputResult("{\"container\": \"{s}\", \"status\": \"{s}\"}", .{containerName, isRunning ? "running" : "stopped"});
    } else {
        outputResult("Container '{s}' is {s}.", .{containerName, isRunning ? "running" : "stopped"});
    }
    std.os.exit(ExitCode.Success);
}

fn stopCommand(args: *std.ArrayList([]const u8)) void {
    if (args.len < 1) {
        printHelp();
        std.os.exit(ExitCode.InvalidArgs);
    }
    const containerName = args.items[0];
    verboseLog("Stopping container: {s}", .{containerName});
    _ = runningContainers.remove(containerName) catch {};

    if (outputFormat == OutputFormat.Json) {
        outputResult("{\"container\": \"{s}\", \"status\": \"stopped\"}", .{containerName});
    } else {
        outputResult("Container '{s}' stopped.", .{containerName});
    }
    std.os.exit(ExitCode.Success);
}

fn listCommand() void {
    verboseLog("Listing containers");
    if (outputFormat == OutputFormat.Json) {
        outputResult("[", .{});
        for (containers) |c, i| {
            const running = runningContainers.get(c) orelse false;
            const comma = if (i == containers.len - 1) "" else ",";
            outputResult("  {\"name\": \"{s}\", \"status\": \"{s}\"}{s}", .{c, running ? "running" : "stopped", comma});
        }
        outputResult("]", .{});
    } else {
        for (containers) |c| {
            const running = runningContainers.get(c) orelse false;
            outputResult("{s} - {s}", .{c, running ? "running" : "stopped"});
        }
    }
    std.os.exit(ExitCode.Success);
}
