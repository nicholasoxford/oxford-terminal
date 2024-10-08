const std = @import("std");

pub const StockInfoObject = struct {
    close: f32,
    date: []u8,

    pub fn deinit(self: *StockInfoObject, allocator: std.mem.Allocator) void {
        allocator.free(self.date);
    }
};

pub const StockInfoResponse = struct {
    symbol: []u8,
    historical: []HistoricalPrice,
};

pub const HistoricalPrice = struct {
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
