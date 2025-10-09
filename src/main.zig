const std = @import("std");
const stdin = std.fs.File.stdin();
const stdout = std.fs.File.stdout();
const expect = std.testing.expect;

const SelectedFlags = struct {
    numberNonBlack: bool,
    numberAll: bool,
    numberCount: usize = 0,
    displayDollar: bool = false,

    pub fn init() SelectedFlags {
        return .{
            .numberAll = false,
            .numberCount = 1,
            .numberNonBlack = false,
            .displayDollar = false,
        };
    }
};

fn printHelp() void {
    const help_text =
        \\zat - A Zig implementation of the cat command
        \\
        \\USAGE:
        \\    zat [OPTIONS] [FILE]...
        \\
        \\OPTIONS:
        \\    -n              Number all output lines
        \\    -b              Number non-blank output lines  
        \\    -E              Display $ at the end of each line
        \\    -h, --help      Show this help message and exit
        \\    --version       Show version information and exit
        \\
        \\EXAMPLES:
        \\    zat file.txt              Print file contents
        \\    zat -n file.txt           Print with line numbers
        \\    zat -b file.txt           Number non-blank lines
        \\    zat -E file.txt           Show line endings
        \\    zat file1.txt file2.txt   Concatenate multiple files
        \\    echo "hello" | zat        Read from stdin
        \\
        \\If no files are specified, zat reads from standard input.
        \\
    ;
    std.debug.print("{s}", .{help_text});
}

fn printVersion() void {
    std.debug.print("zat version 1.0.0\n", .{});
}

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
        if (std.mem.eql(u8, value, "-h") or std.mem.eql(u8, value, "--help")) {
            printHelp();
            std.posix.exit(0);
        }
        if (std.mem.eql(u8, value, "--version")) {
            printVersion();
            std.posix.exit(0);
        }
        if (std.mem.eql(u8, value, "-n")) {
            flags.numberAll = true;
            continue;
        }
        if (std.mem.eql(u8, value, "-b")) {
            flags.numberNonBlack = true;
            flags.numberAll = false;
            continue;
        }
        if (std.mem.eql(u8, value, "-E")) {
            flags.displayDollar = true;
            continue;
        }
        const file = std.fs.cwd().openFile(value, .{ .mode = .read_only }) catch {
            try out.writeAll("zat: ");
            try out.writeAll(value);
            try out.writeAll(": No such file or directory\n");
            try out.flush();
            std.posix.exit(1);
            unreachable;
        };
        defer file.close();

        var buf_file: [1024]u8 = undefined;
        var reader = file.reader(&buf_file);

        const page_alloc = std.heap.page_allocator;

        var allocating_writer = std.Io.Writer.Allocating.init(page_alloc);

        while (reader.interface.streamDelimiter(&allocating_writer.writer, '\n')) |_| {
            const line = allocating_writer.written();
            if (flags.numberAll) {
                const space = switch (flags.numberCount) {
                    0...9 => "     ",
                    10...99 => "    ",
                    100...999 => "   ",
                    1000...99999 => "  ",
                    else => "  ",
                };
                try out.print("{s}{d}  {s}{s}\n", .{ space, flags.numberCount, line, if (flags.displayDollar) "$" else "" });
                flags.numberCount += 1;
                try out.flush();
                allocating_writer.clearRetainingCapacity();
                reader.interface.toss(1);
                continue;
            }

            if (flags.numberNonBlack) {
                const space = switch (flags.numberCount) {
                    0...9 => "     ",
                    10...99 => "    ",
                    100...999 => "   ",
                    1000...99999 => "  ",
                    else => " ",
                };
                const number_space = switch (flags.numberCount) {
                    0...9 => " ",
                    10...99 => "  ",
                    100...999 => "   ",
                    1000...9999 => "    ",
                    else => "     ",
                };

                var is_blanck = true;
                for (line) |c| {
                    switch (c) {
                        '\r', '\n' => {},
                        else => is_blanck = false,
                    }
                }

                if (is_blanck) {
                    try out.print("{s}{s}  {s}{s}\n", .{ space, number_space, line, if (flags.displayDollar) "$" else "" });
                } else {
                    try out.print("{s}{d}  {s}{s}\n", .{ space, flags.numberCount, line, if (flags.displayDollar) "$" else "" });
                    flags.numberCount += 1;
                }
                try out.flush();
                allocating_writer.clearRetainingCapacity();
                reader.interface.toss(1);
                continue;
            }
            try out.writeAll(line);
            if (flags.displayDollar) try out.writeAll("$");
            try out.writeAll("\n");
            try out.flush();
            allocating_writer.clearRetainingCapacity();
            reader.interface.toss(1);
        } else |err| {
            if (err != error.EndOfStream) return err;
        }
    }
}
