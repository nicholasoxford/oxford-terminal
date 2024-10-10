const std = @import("std");
const data = @import("data.zig");
const curl = @cImport({
    @cInclude("curl/curl.h");
});

/// Error Codes Specific to Network Module
pub const NetworkError = error{
    CURLGlobalInitFailed,
    CURLHandleInitFailed,
    CouldNotSetURL,
    CouldNotSetWriteCallback,
    FailedToPerformRequest,
    JSONParseError,
};

pub fn removeTrailingNullBytes(slice: []const u8) []const u8 {
    var end: usize = slice.len;
    while (end > 0 and slice[end - 1] == 0) {
        end -= 1;
    }
    return slice[0..end];
}

/// Fetches stock data for a given symbol.
pub fn fetchStockData(
    allocator: std.mem.Allocator,
    symbol: []const u8,
    data_out: *std.ArrayList(data.StockInfoObject),
) !void {
    const baseUrl = "https://financialmodelingprep.com/api/v3/historical-price-full/";
    const apiKey = "ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az"; // Make sure this is your actual API key
    const trimmedSymbol = removeTrailingNullBytes(symbol);

    const url = try std.fmt.allocPrintZ(allocator, "{s}{s}?apikey={s}", .{ baseUrl, trimmedSymbol, apiKey });

    // Global CURL initializations
    if (curl.curl_global_init(curl.CURL_GLOBAL_ALL) != curl.CURLE_OK)
        return NetworkError.CURLGlobalInitFailed;
    defer curl.curl_global_cleanup();

    // Initialize CURL handle
    const handle = curl.curl_easy_init() orelse return NetworkError.CURLHandleInitFailed;
    defer curl.curl_easy_cleanup(handle);

    // Response buffer
    var response_buffer = std.ArrayList(u8).init(allocator);
    defer response_buffer.deinit();

    // Set CURL options
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_URL, url.ptr) != curl.CURLE_OK)
        return NetworkError.CouldNotSetURL;

    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != curl.CURLE_OK)
        return NetworkError.CouldNotSetWriteCallback;
    if (curl.curl_easy_setopt(handle, curl.CURLOPT_WRITEDATA, &response_buffer) != curl.CURLE_OK)
        return NetworkError.CouldNotSetWriteCallback;

    // Perform the request
    if (curl.curl_easy_perform(handle) != curl.CURLE_OK)
        return NetworkError.FailedToPerformRequest;

    std.debug.print("Got response of {d} bytes\n", .{response_buffer.items.len});

    // Parse the JSON response
    const parse_result = std.json.parseFromSlice(data.StockInfoResponse, allocator, response_buffer.items, .{}) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.debug.print("Body: {s}\n", .{response_buffer.items});
        return err;
    };
    defer parse_result.deinit();

    // Process the historical data
    for (parse_result.value.historical) |item| {
        const date_copy = try allocator.dupe(u8, item.date);
        data_out.append(data.StockInfoObject{
            .date = date_copy,
            .close = item.close,
        }) catch |err| {
            std.debug.print("Error: {}\n", .{err});
            std.debug.print("Body: {s}\n", .{response_buffer.items});
            return err;
        };
    }
}
/// Callback function for CURL to write data into the response buffer.
fn writeToArrayListCallback(ptr: ?*anyopaque, size: usize, nmemb: usize, user_data: ?*anyopaque) callconv(.C) usize {
    const buffer: *std.ArrayList(u8) = @ptrCast(@alignCast(user_data));
    const data_slice = @as([*]const u8, @ptrCast(ptr.?))[0 .. size * nmemb];
    buffer.appendSlice(data_slice) catch return 0;
    return size * nmemb;
}
