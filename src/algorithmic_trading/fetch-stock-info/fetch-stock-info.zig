const ray = @import("../../raylib.zig");

pub const FetchStockInfo = struct {
    pub fn fetchStockInfo() void {
        // Implement fetching stock info logic here
        ray.TraceLog(ray.LOG_INFO, "Fetching stock info...");
    }
    pub fn drawState() void {
        ray.DrawText("Fetching stock info...", 190, 200, 20, ray.WHITE);
    }
};
