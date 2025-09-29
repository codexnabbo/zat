const std = @import("std");
const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();
const expect = std.testing.expect;

const SelectedFlags = struct {
    numberNonBlack: bool,
    numberAll: bool,
    numberCount: usize = 0,

    pub fn init() SelectedFlags {
        return .{
            .numberAll = false,
            .numberCount = 1,
            .numberNonBlack = false,
        };
    }
};

pub fn main() !void {
    var buf_in: [64 * 1024]u8 = undefined;
    var buf_out: [64 * 1024]u8 = undefined;
    var buf_args: [1024 * 1024]u8 = undefined;
    var flags: SelectedFlags = SelectedFlags.init();

    var fba = std.heap.FixedBufferAllocator.init(&buf_args);
    const allocator = fba.allocator();

    var stdout_writer = stdout.writer(&buf_out);
    const out = &stdout_writer.interface;

    var len: usize = 0;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len <= 1) {
        while (true) {
            len = try stdin.read(&buf_in);
            if (len == 0) break;
            try out.writeAll(buf_in[0..len]);
            try out.flush();
        }

        std.posix.exit(0);
    }

    for (args[1..]) |value| {
        if (std.mem.eql(u8, value, "-n")) {
            flags.numberAll = true;
            continue;
        }
        const file = std.fs.cwd().openFile(value, .{ .mode = .read_only }) catch |err| switch (err) {
            error.FileNotFound => {
                try out.writeAll("File Not Found\n");
                try out.flush();
                std.posix.exit(1);
                unreachable;
            },
            else => {
                try out.writeAll("File Not Found\n");
                try out.flush();
                std.posix.exit(1);
                unreachable;
            },
        };
        defer file.close();

        var buf_file: [1024]u8 = undefined;
        var reader = file.reader(&buf_file);
        while (reader.interface.takeDelimiterInclusive('\n')) |line| {
            if (flags.numberAll) {
                const space = switch (flags.numberCount) {
                    0...9 => "     ",
                    10...99 => "    ",
                    100...999 => "   ",
                    else => "  ",
                };
                try out.print("{s}{d}  {s}", .{ space, flags.numberCount, line });
                flags.numberCount += 1;
                try out.flush();
                continue;
            }
            try out.writeAll(line);
            try out.flush();
        } else |err| {
            if (err != error.EndOfStream) return err;
        }
    }
}
