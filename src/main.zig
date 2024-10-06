const std = @import("std");
const ray = @import("raylib.zig");

pub fn main() !void {
    try ray_main();
}

fn ray_main() !void {
    const width = 800;
    const height = 800;
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT | ray.FLAG_VSYNC_HINT);
    ray.InitWindow(width, height, "Zig Raylib Example");
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
    var app_state = AppState.Menu;

    // Selected menu option
    var selected_menu_option: MenuOption = .FirstOption;

    // Main loop
    while (!ray.WindowShouldClose()) {
        // Update
        switch (app_state) {
            .Menu => {
                handleMenuState(&app_state, &selected_menu_option);
            },
            .AlgorithmicTrading => {
                handleAlgorithmicTradingState(&app_state);
            },
            // Add more states as needed
        }

        // Draw
        {
            ray.BeginDrawing();
            defer ray.EndDrawing();

            ray.ClearBackground(ray.BLACK);

            switch (app_state) {
                .Menu => {
                    drawMenu(selected_menu_option);
                },
                .AlgorithmicTrading => {
                    drawAlgorithmicTrading();
                },
                // Add more states as needed
            }
        }
    }
}

// Application states
const AppState = enum {
    Menu,
    AlgorithmicTrading,
    // Add more states as needed
};

// Menu options
const MenuOption = enum {
    FirstOption,
    SecondOption,
    ThirdOption,
};

fn handleMenuState(app_state: *AppState, selected_menu_option: *MenuOption) void {
    // Handle menu input

    const mouse_pos = ray.GetMousePosition();

    const menu_options = [_][]const u8{
        "Algorithmic Trading",
        "Neural Networks",
        "Leetcode Notes",
    };

    const base_x = 120;
    var y: c_int = 50;
    const font_size = 40;

    var found_hover = false;

    for (menu_options, 0..) |option, index| {
        const text_width = ray.MeasureText(option.ptr, font_size);
        const text_height = font_size; // Approximate text height
        const rect = ray.Rectangle{
            .x = @as(f32, @floatFromInt(base_x)),
            .y = @as(f32, @floatFromInt(y)),
            .width = @as(f32, @floatFromInt(text_width)),
            .height = @as(f32, @floatFromInt(text_height)),
        };
        if (ray.CheckCollisionPointRec(mouse_pos, rect)) {
            selected_menu_option.* = @enumFromInt(index);
            found_hover = true;
            if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
                // Transition to the next state based on selected option
                switch (selected_menu_option.*) {
                    .FirstOption => {
                        app_state.* = .AlgorithmicTrading;
                    },
                    .SecondOption => {
                        // Handle second option
                    },
                    .ThirdOption => {
                        // Handle third option
                    },
                }
            }
        }
        y += font_size + 10;
    }

    // If mouse is not over any option, handle keyboard input
    if (!found_hover) {
        if (ray.IsKeyPressed(ray.KEY_UP)) {
            if (@intFromEnum(selected_menu_option.*) > 0) {
                selected_menu_option.* = @enumFromInt(@intFromEnum(selected_menu_option.*) - 1);
            }
        }
        if (ray.IsKeyPressed(ray.KEY_DOWN)) {
            if (@intFromEnum(selected_menu_option.*) < @intFromEnum(MenuOption.ThirdOption)) {
                selected_menu_option.* = @enumFromInt(@intFromEnum(selected_menu_option.*) + 1);
            }
        }
        if (ray.IsKeyPressed(ray.KEY_ENTER)) {
            // Transition to the next state based on selected option
            switch (selected_menu_option.*) {
                .FirstOption => {
                    app_state.* = .AlgorithmicTrading;
                },
                .SecondOption => {
                    // Handle second option
                },
                .ThirdOption => {
                    // Handle third option
                },
            }
        }
    }
}

fn drawMenu(selected_menu_option: MenuOption) void {
    const menu_options = [_][]const u8{
        "Algorithmic Trading",
        "Neural Networks",
        "Leetcode Notes",
    };

    const base_x = 120;
    var y: c_int = 50;
    const font_size = 40;

    for (menu_options, 0..) |option, index| {
        const color = if (index == @intFromEnum(selected_menu_option)) ray.GREEN else ray.WHITE;
        ray.DrawText(option.ptr, base_x, y, font_size, color);
        y += font_size + 10;
    }
}

fn handleAlgorithmicTradingState(app_state: *AppState) void {
    // Handle game input and logic
    // print key pressed
    if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
        // Return to menu
        app_state.* = .Menu;
    }
    // Add game logic here
}

fn drawAlgorithmicTrading() void {
    ray.DrawText("Algorithmic Trading State", 190, 200, 20, ray.WHITE);
    // Draw game elements here
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
