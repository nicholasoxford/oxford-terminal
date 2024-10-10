const ray = @import("../../raylib.zig");
const std = @import("std");
const data = @import("../../data.zig");
const network = @import("../../network.zig");
const curl = @cImport({
    @cInclude("curl/curl.h");
});

const TICKER_INPUT_BOX: ray.Rectangle = ray.Rectangle{ .x = 190, .y = 220, .width = 200, .height = 30 };
pub const MAX_INPUT_CHARS: usize = 9;

pub var mouseOnTickerInput: bool = false;
pub var tickerSymbol: [MAX_INPUT_CHARS + 1]u8 = [_]u8{0} ** (MAX_INPUT_CHARS + 1);
pub var letterCount: usize = 0;
pub var framesCounter: i32 = 0;

pub const FetchStockInfo = struct {
    pub const StockInfoList = std.ArrayList(data.StockInfoObject);
    stockInfo: StockInfoList,
    gpa: std.mem.Allocator,
    stockTicker: []u8,
    const API_KEY = "ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az";

    pub fn init(allocator: std.mem.Allocator) FetchStockInfo {
        return .{
            .stockInfo = StockInfoList.init(allocator),
            .gpa = allocator,
            .stockTicker = undefined,
        };
    }

    pub fn deinit(self: *FetchStockInfo) void {
        for (self.stockInfo.items) |*item| {
            item.deinit(self.gpa);
        }
        self.stockInfo.deinit();
    }

    pub fn drawState(self: *FetchStockInfo, fetchingStockInfo: *bool, hasFetchedInfo: *bool) void {
        if (hasFetchedInfo.*) {
            self.drawGraph();
        } else if (fetchingStockInfo.*) {
            drawFetchingStockInfo();
        } else {
            self.drawTickerInput(fetchingStockInfo, hasFetchedInfo);
        }
    }

    fn fetchStockInfo(self: *FetchStockInfo, stockTicker: []const u8, hasFetchedInfo: *bool, fetchingStockInfo: *bool) !void {
        // Clear previous data
        for (self.stockInfo.items) |*item| {
            item.deinit(self.gpa);
        }
        self.stockInfo.clearRetainingCapacity();

        try network.fetchStockData(self.gpa, stockTicker, &self.stockInfo);

        hasFetchedInfo.* = true;
        fetchingStockInfo.* = false;
    }

    fn drawGraph(self: *FetchStockInfo) void {
        // create text with stockTicker
        const ticketGraphText = std.fmt.allocPrint(self.gpa, "Graph for {s}", .{self.stockTicker}) catch |err| {
            std.debug.print("Error allocating memory for graph text: {}\n", .{err});
            return;
        };
        defer self.gpa.free(ticketGraphText);
        ray.DrawText(ticketGraphText.ptr, 150, 80, 20, ray.WHITE);

        if (self.stockInfo.items.len == 0) {
            ray.DrawText("No stock data available", 190, 200, 20, ray.WHITE);
            return;
        }

        ray.DrawText("Stock data available", 150, 400, 20, ray.WHITE);

        // Draw the actual graph here
        const startX: f32 = 100;
        const startY: f32 = 400;
        const width: f32 = 600;
        const height: f32 = 300;

        ray.DrawRectangleLines(@intFromFloat(startX), @intFromFloat(startY - height), @intFromFloat(width), @intFromFloat(height), ray.WHITE);

        if (self.stockInfo.items.len > 1) {
            var max_price: f32 = self.stockInfo.items[0].close;
            var min_price: f32 = self.stockInfo.items[0].close;

            for (self.stockInfo.items) |item| {
                if (item.close > max_price) max_price = item.close;
                if (item.close < min_price) min_price = item.close;
            }

            const price_range = max_price - min_price;
            const x_step = width / @as(f32, @floatFromInt(self.stockInfo.items.len - 1));

            for (self.stockInfo.items, 0..) |item, i| {
                const x = startX + @as(f32, @floatFromInt(i)) * x_step;
                const y = startY - ((item.close - min_price) / price_range) * height;

                if (i > 0) {
                    const prev_x = startX + @as(f32, @floatFromInt(i - 1)) * x_step;
                    const prev_y = startY - ((self.stockInfo.items[i - 1].close - min_price) / price_range) * height;
                    ray.DrawLine(@intFromFloat(prev_x), @intFromFloat(prev_y), @intFromFloat(x), @intFromFloat(y), ray.GREEN);
                }

                ray.DrawCircle(@intFromFloat(x), @intFromFloat(y), 3, ray.RED);
            }
        }
    }

    fn drawFetchingStockInfo() void {
        var fetchingText: [100]u8 = undefined;
        const fetchingSlice = std.fmt.bufPrint(&fetchingText, "Fetching stock info for {s}...", .{tickerSymbol}) catch unreachable;
        ray.DrawText(@ptrCast(fetchingSlice.ptr), 190, 200, 20, ray.WHITE);
    }

    fn drawTickerInput(self: *FetchStockInfo, fetchingStockInfo: *bool, hasFetchedInfo: *bool) void {
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

        if (ray.IsKeyPressed(ray.KEY_ENTER) and letterCount > 0) {
            std.debug.print("Enter pressed\n", .{});
            fetchingStockInfo.* = true;
            self.stockTicker = std.fmt.allocPrint(self.gpa, "{s}", .{tickerSymbol}) catch |err| {
                std.debug.print("Error allocating memory for stock ticker: {}\n", .{err});
                fetchingStockInfo.* = false;
                return;
            };

            self.fetchStockInfo(self.stockTicker, hasFetchedInfo, fetchingStockInfo) catch |err| {
                std.debug.print("Error fetching stock info: {}\n", .{err});
                fetchingStockInfo.* = false;
                self.gpa.free(self.stockTicker);
            };
        }
    }
};

fn writeToArrayListCallback(dataPtr: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer: *std.ArrayList(u8) = @alignCast(@ptrCast(user_data));
    var typed_data: [*]u8 = @ptrCast(dataPtr);
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}
