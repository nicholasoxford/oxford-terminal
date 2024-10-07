const ray = @import("../../raylib.zig");
const std = @import("std");
const curl = @cImport({
    @cInclude("curl/curl.h");
});

const TICKER_INPUT_BOX: ray.Rectangle = ray.Rectangle{ .x = 190, .y = 220, .width = 200, .height = 30 };
pub const MAX_INPUT_CHARS: usize = 9;

pub var mouseOnTickerInput: bool = false;
pub var tickerSymbol: [MAX_INPUT_CHARS + 1]u8 = [_]u8{0} ** (MAX_INPUT_CHARS + 1);
pub var letterCount: usize = 0;
pub var framesCounter: i32 = 0;

pub const StockInfoObject = struct {
    close: f32,
    date: []const u8,
};

pub const StockInfoList = std.ArrayList(StockInfoObject);

pub const FetchStockInfo = struct {
    pub fn drawState(fetchingStockInfo: *bool, hasFetchedInfo: *bool) void {
        // print fetchingStockInfo
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

    if (ray.IsKeyPressed(ray.KEY_ENTER) and letterCount > 0) {
        std.debug.print("Enter pressed\n", .{});
        fetchingStockInfo.* = true;
        fetchStockInfo(&tickerSymbol, hasFetchedInfo, fetchingStockInfo) catch |err| {
            std.debug.print("Error fetching stock info: {}\n", .{err});
        };
    }
}

const API_KEY = "ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az";
fn fetchStockInfo(stockTicker: []const u8, hasFetchedInfo: *bool, fetchingStockInfo: *bool) !void {
    const ref_url = "https://financialmodelingprep.com/api/v3/historical-price-full/AAPL?apikey=ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az";
    std.debug.print("ref_url: {s}\n", .{ref_url});
    std.debug.print("stockTicker: {s}\n", .{stockTicker});

    // We need an allocator to create a std.http.Client
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_impl.deinit();
    const gpa = gpa_impl.allocator();
    var StockInfo = StockInfoList.init(gpa);
    defer StockInfo.deinit();

    // global curl init, or fail
    if (curl.curl_global_init(curl.CURL_GLOBAL_ALL) != curl.CURLE_OK)
        return error.CURLGlobalInitFailed;
    defer curl.curl_global_cleanup();

    // curl easy handle init, or fail
    const handle = curl.curl_easy_init() orelse return error.CURLHandleInitFailed;
    defer curl.curl_easy_cleanup(handle);

    // response buffer
    var response_buffer = std.ArrayList(u8).init(gpa);
    defer response_buffer.deinit();

    // setup curl options
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_URL, @as([*c]const u8, ref_url)) != curl.CURLE_OK)
        return error.CouldNotSetURL;
    // set write function callbacks
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != curl.CURLE_OK)
        return error.CouldNotSetWriteCallback;
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEDATA, &response_buffer) != curl.CURLE_OK)
        return error.CouldNotSetWriteCallback;

    // perform
    if (curl.curl_easy_perform(handle) != curl.CURLE_OK)
        return error.FailedToPerformRequest;

    std.log.info("Got response of {d} bytes", .{response_buffer.items.len});
    std.debug.print("{s}\n", .{response_buffer.items});
    const data = std.json.parseFromSlice(StockInfoReponse, gpa, response_buffer.items, .{}) catch |err| {
        std.debug.print("Error parsing JSON: {}\n", .{err});
        return err;
    };
    defer data.deinit();
    // grab second item in historical
    const historical = data.value.historical[0..4];

    for (historical) |item| {
        try StockInfo.append(StockInfoObject{ .date = item.date, .close = item.close });
    }

    // print close
    std.debug.print("Close: {e}\n", .{historical[0].close});
    // low
    std.debug.print("Low: {e}\n", .{historical[0].low});
    // volume
    std.debug.print("Volume: {}\n", .{historical[0].volume});
    // label
    std.debug.print("Label: {s}\n", .{historical[0].label});

    hasFetchedInfo.* = true;
    fetchingStockInfo.* = false;
}

const StockInfoReponse = struct {
    symbol: []u8,
    historical: []HistoricalPrice,
};

const HistoricalPrice = struct {
    date: []const u8,
    open: f32,
    high: f32,
    low: f32,
    close: f32,
    adjClose: f32,
    volume: u64,
    unadjustedVolume: u64,
    change: f32,
    changePercent: f32,
    vwap: f32,
    label: []const u8,
    changeOverTime: f32,
};
fn writeToArrayListCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer: *std.ArrayList(u8) = @alignCast(@ptrCast(user_data));
    var typed_data: [*]u8 = @ptrCast(data);
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}
