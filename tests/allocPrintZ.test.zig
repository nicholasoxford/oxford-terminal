const std = @import("std");
const testing = std.testing;

test "allocPrintZ URL construction" {
    const allocator = testing.allocator;

    const baseUrl = "https://financialmodelingprep.com/api/v3/historical-price-full/";
    const symbol: []const u8 = "AAPL";
    const apiKey = "ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az";

    // Test case 1: Basic URL construction
    {
        const url = try std.fmt.allocPrintZ(allocator, "{s}{s}?apikey={s}", .{ baseUrl, symbol, apiKey });
        defer allocator.free(url);

        try testing.expectEqualStrings("https://financialmodelingprep.com/api/v3/historical-price-full/AAPL?apikey=ZMbEKCtq28UHoqaC5IZO0CCzACvcs6Az", url);
        try testing.expectEqual(@as(u8, 0), url[url.len]); // Ensure null termination
    }

    // Test case 2: Verify span of the constructed URL
    // {
    //     const url = try std.fmt.allocPrintZ(allocator, "{s}{s}?apikey={s}", .{ baseUrl, symbol, apiKey });
    //     defer allocator.free(url);

    //     const url_span = std.mem.span(url.ptr);
    //     try testing.expectEqualStrings("https://api.example.com/AAPL?apikey=testkey123", url_span);
    //     std.debug.print("URL Span: {s}\n", .{url_span});
    //     std.debug.print("URL Span Length: {d}\n", .{url_span.len});
    //     std.debug.print("URL : {d}\n", .{url});
    //     std.debug.print("URL Length: {d}\n", .{url.len});

    //     try testing.expect(url_span.len < url.len); // Span should not include null terminator
    // }

    // Test case 3: Simulate CURL usage with pointer cast
    // {
    //     const url = try std.fmt.allocPrintZ(allocator, "{s}{s}?apikey={s}", .{ baseUrl, symbol, apiKey });
    //     defer allocator.free(url);

    //     const c_url: [*c]const u8 = @ptrCast(url);
    //     const reconstructed_url = std.mem.span(c_url);
    //     try testing.expectEqualStrings("https://api.example.com/AAPL?apikey=testkey123", reconstructed_url);
    // }

    // // Test case 4: Verify behavior with empty strings
    // {
    //     const empty_symbol = "";
    //     const url = try std.fmt.allocPrintZ(allocator, "{s}{s}?apikey={s}", .{ baseUrl, empty_symbol, apiKey });
    //     defer allocator.free(url);

    //     try testing.expectEqualStrings("https://api.example.com/?apikey=testkey123", url);
    // }
}
