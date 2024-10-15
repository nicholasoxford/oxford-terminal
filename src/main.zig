const std = @import("std");
const ray = @import("raylib.zig");

const AppState = @import("app_state.zig");
const MainMenu = @import("main_menu.zig");
const objc = @import("objC.zig");
const TradingMenu = @import("trading_menu.zig").TradingMenu;

pub fn main() !void {
    try rayMain();
}

fn rayMain() !void {
    const width = 800;
    const height = 800;
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT | ray.FLAG_VSYNC_HINT);
    ray.InitWindow(width, height, "Oxford Terminal");
    ray.SetExitKey(ray.KEY_NULL);

    defer ray.CloseWindow();

    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 8 }){};
    defer {
        switch (gpa.deinit()) {
            .leak => @panic("leaked memory"),
            else => {},
        }
    }

    // Application state
    var app_state = AppState.AppState.Menu;
    AppState.current_app_state = &app_state; // Initialize the global pointer

    var trading_menu = TradingMenu.init(&app_state, gpa.allocator());
    AppState.current_trading_menu = &trading_menu;

    // Selected menu option
    var main_menu = MainMenu.MainMenu.init(&app_state);

    const is_at_least_macos_14 = try objc.checkMacOSAndMetal(14, 2, 2);
    std.log.debug("Is at least macOS 14.2.2: {d}", .{@intFromBool(is_at_least_macos_14)});
    // Main loop
    while (!ray.WindowShouldClose()) {
        // Update
        switch (app_state) {
            .Menu => {
                try main_menu.handleState();
            },
            .AlgorithmicTrading => {
                trading_menu.handleState();
            },
            .NeuralNetworks => {
                // Handle Neural Networks state
            },
            .LeetcodeNotes => {
                // Handle Leetcode Notes state
            },
            .Exit => {
                break; // Exit the main loop
            },
        }

        // Draw
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.BLACK);

        switch (app_state) {
            .Menu => {
                main_menu.drawState();
            },
            .AlgorithmicTrading => {
                trading_menu.drawState();
            },
            .NeuralNetworks => {
                // Draw Neural Networks state
            },
            .LeetcodeNotes => {
                // Draw Leetcode Notes state
            },
            .Exit => {
                // Optionally, display a goodbye message or perform cleanup
            },
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
