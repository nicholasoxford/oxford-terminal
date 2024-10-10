const std = @import("std");
const ray = @import("../raylib.zig");
const AppState = @import("../app_state.zig");
const MenuModule = @import("../ui/menu.zig");

pub const MainMenu = struct {
    app_state: *AppState.AppState,
    menu: MenuModule.Menu,

    pub fn init(app_state: *AppState.AppState) MainMenu {
        return .{
            .app_state = app_state,
            .menu = MenuModule.Menu{
                .items = &[_]MenuModule.MenuItem{
                    .{ .label = "Algorithmic Trading", .action = &algorithmicTradingAction },
                    .{ .label = "Neural Networks", .action = &neuralNetworksAction },
                    .{ .label = "Leetcode Notes", .action = &leetcodeNotesAction },
                    .{ .label = "Exit", .action = &exitAction },
                },
                .font_size = 30,
                .base_x = 120,
                .base_y = 80,
            },
        };
    }

    pub fn handleState(self: *MainMenu) !void {
        self.menu.handleInput();
    }

    pub fn drawState(self: MainMenu) void {
        self.menu.draw();
        const MAIN_MENU_TEXT = "Main Menu";
        // center text
        const text_width = ray.MeasureText(MAIN_MENU_TEXT, self.menu.font_size);

        const text_x = @divTrunc(ray.GetScreenWidth() - text_width, 2);

        ray.DrawText(MAIN_MENU_TEXT, text_x, 40, self.menu.font_size, ray.WHITE);
    }
};

// Action Functions
fn algorithmicTradingAction() void {
    ray.TraceLog(ray.LOG_INFO, "Entering Algorithmic Trading state...");
    if (AppState.current_app_state) |state_ptr| {
        state_ptr.* = .AlgorithmicTrading;
    }
}

fn neuralNetworksAction() void {
    ray.TraceLog(ray.LOG_INFO, "Neural Networks option selected");
    if (AppState.current_app_state) |state_ptr| {
        state_ptr.* = .NeuralNetworks;
    }
}

fn leetcodeNotesAction() void {
    ray.TraceLog(ray.LOG_INFO, "Leetcode Notes option selected");
    if (AppState.current_app_state) |state_ptr| {
        state_ptr.* = .LeetcodeNotes;
    }
}

fn exitAction() void {
    ray.TraceLog(ray.LOG_INFO, "Exit option selected");
    if (AppState.current_app_state) |state_ptr| {
        state_ptr.* = .Exit;
    }
}
