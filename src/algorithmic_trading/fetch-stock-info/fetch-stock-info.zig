const ray = @import("../../raylib.zig");
const std = @import("std");

const TICKER_INPUT_BOX: ray.Rectangle = ray.Rectangle{ .x = 190, .y = 220, .width = 200, .height = 30 };
pub const MAX_INPUT_CHARS: usize = 9;

pub var mouseOnTickerInput: bool = false;
pub var tickerSymbol: [MAX_INPUT_CHARS + 1]u8 = [_]u8{0} ** (MAX_INPUT_CHARS + 1);
pub var letterCount: usize = 0;
pub var framesCounter: i32 = 0;

pub const FetchStockInfo = struct {
    pub fn drawState(fetchingStockInfo: *bool, hasFetchedInfo: *bool) void {
        // print fetchingStockInfo
        std.debug.print("fetchingStockInfo: {}\n", .{fetchingStockInfo.*});
        if (hasFetchedInfo.*) {
            drawGraph();
        } else if (fetchingStockInfo.*) {
            drawFetchingStockInfo();
        } else {
            drawTickerInput(fetchingStockInfo, hasFetchedInfo);
        }
    }
};

fn drawGraph() void {
    ray.DrawText("Fetching stock info...", 190, 200, 20, ray.WHITE);
}

fn drawFetchingStockInfo() void {
    var fetchingText: [100]u8 = undefined;
    const fetchingSlice = std.fmt.bufPrint(&fetchingText, "Fetching stock info for {s}...", .{tickerSymbol}) catch unreachable;
    ray.DrawText(@ptrCast(fetchingSlice.ptr), 190, 200, 20, ray.WHITE);
}

fn drawTickerInput(fetchingStockInfo: *bool, hasFetchedInfo: *bool) void {
    ray.DrawText("Enter ticker symbol:", 190, 200, 20, ray.WHITE);

    if (ray.CheckCollisionPointRec(ray.GetMousePosition(), TICKER_INPUT_BOX)) {
        mouseOnTickerInput = true;
        ray.SetMouseCursor(ray.MOUSE_CURSOR_IBEAM);

        const key = ray.GetCharPressed();
        while (key > 0) {
            if ((key >= 32) and (key <= 125) and (letterCount < MAX_INPUT_CHARS)) {
                tickerSymbol[letterCount] = @intCast(key);
                tickerSymbol[letterCount + 1] = 0; // Null terminator
                letterCount += 1;
            }
            // Check next character in the queue
            const nextKey = ray.GetCharPressed();
            if (nextKey == 0) break;
        }

        if (ray.IsKeyPressed(ray.KEY_BACKSPACE)) {
            if (letterCount > 0) {
                letterCount -= 1;
                tickerSymbol[letterCount] = 0;
            }
        }

        framesCounter += 1;
    } else {
        mouseOnTickerInput = false;
        ray.SetMouseCursor(ray.MOUSE_CURSOR_DEFAULT);
        framesCounter = 0;
    }

    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        for (0..tickerSymbol.len) |i| {
            tickerSymbol[i] = 0;
        }
        fetchingStockInfo.* = false;
        hasFetchedInfo.* = false;
        letterCount = 0;
        // set tickerSymbol to empty string

    }

    ray.DrawRectangleRec(TICKER_INPUT_BOX, ray.LIGHTGRAY);
    if (mouseOnTickerInput) {
        ray.DrawRectangleLinesEx(TICKER_INPUT_BOX, 2, ray.GOLD);
    } else {
        ray.DrawRectangleLinesEx(TICKER_INPUT_BOX, 2, ray.DARKGRAY);
    }

    ray.DrawText(&tickerSymbol, @intFromFloat(TICKER_INPUT_BOX.x + 5), @intFromFloat(TICKER_INPUT_BOX.y + 8), 20, ray.MAROON);

    if (mouseOnTickerInput) {
        if (letterCount < MAX_INPUT_CHARS) {
            if (@mod(@divTrunc(framesCounter, 20), 2) == 0) {
                ray.DrawText("_", @intFromFloat(TICKER_INPUT_BOX.x + 8 + @as(f32, @floatFromInt(ray.MeasureText(&tickerSymbol, 20)))), @intFromFloat(TICKER_INPUT_BOX.y + 12), 20, ray.MAROON);
            }
        } else {
            ray.DrawText("Press BACKSPACE to delete chars...", 230, 300, 20, ray.GRAY);
        }
    }
    if (ray.IsKeyPressed(ray.KEY_ENTER)) {
        std.debug.print("Enter pressed\n", .{});
        fetchingStockInfo.* = true;
    }
}
