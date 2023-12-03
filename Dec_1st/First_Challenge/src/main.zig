const std = @import("std");
const testing = std.testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("src/puzzle.txt", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();

    var result: isize = 0;
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var calibrationValue = try getCalibrationValue(arr.items);

        result = result + calibrationValue;

        arr.clearRetainingCapacity();
    }
    std.debug.print("result: {d}\n", .{result});
}

fn isDigit(byte: u8) bool {
    return byte >= '0' and byte <= '9'; // ASCII range for '0' to '9'
}

fn getDigits(bytes: []const u8) ![]u8 {
    var digits = std.ArrayList(u8).init(std.heap.page_allocator);
    defer digits.deinit();

    for (bytes) |elem| {
        if (isDigit(elem)) {
            try digits.append(elem);
        }
    }

    return digits.toOwnedSlice();
}

fn combineDigits(first: u8, last: u8) !i16 {
    var buffer: [2]u8 = undefined;
    buffer[0] = first;
    buffer[1] = last;

    var combination: []u8 = buffer[0..];
    var result: i16 = 0;
    for (combination) |digit| {
        const intValue = @as(i16, @intCast(digit - '0'));
        result = result * 10 + intValue;
    }

    return result;
}

fn getCalibrationValue(sentence: []const u8) !i16 {
    var digits = try getDigits(sentence);
    if (digits.len == 0) {
        return 0;
    }

    var firstDigit = digits[0];
    var lastDigit = digits[digits.len - 1];

    return combineDigits(firstDigit, lastDigit);
}

test "isDigit with valid digits" {
    const validDigits = "0123456789";
    for (validDigits) |byte| {
        const result = isDigit(byte);
        testing.expect(result).toBe(true);
    }
}

test "isDigit with non-digits" {
    const nonDigits = "abcABC!@#$";
    for (nonDigits) |byte| {
        const result = isDigit(byte);
        testing.expect(result).toBe(false);
    }
}
