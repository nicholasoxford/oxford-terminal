const ray = @import("../raylib.zig");
const std = @import("std");
const AppState = @import("../app_state.zig");
const MenuModule = @import("../ui/menu.zig");
const FetchStockInfo = @import("./fetch-stock-info/fetch-stock-info.zig");

pub const TradingMenuState = enum {
    TradingMenu,
    FetchStockInfo,
    BackToMainMenu,
};

pub var fetchingStockInfo: bool = false;
pub var hasFetchedInfo: bool = false;

pub const TradingMenu = struct {
    app_state: *AppState.AppState,
    menu: MenuModule.Menu,
    state: TradingMenuState,

    pub fn init(app_state: *AppState.AppState) TradingMenu {
        return .{
            .app_state = app_state,
            .menu = MenuModule.Menu{
                .items = &[_]MenuModule.MenuItem{
                    .{ .label = "Fetch Stock Info", .action = &fetchStockInfoAction },
                    .{ .label = "Back to Main Menu", .action = &backToMainMenuAction },
                },
                .font_size = 30,
                .base_x = 120,
                .base_y = 50,
            },
            .state = .TradingMenu,
        };
    }

    pub fn handleState(self: *TradingMenu) void {
        switch (self.state) {
            .TradingMenu => {
                self.menu.handleInput();
                if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
                    self.state = .BackToMainMenu;
                }
            },
            .FetchStockInfo => {
                // Handle FetchStockInfo state
                if (ray.IsKeyPressed(ray.KEY_ESCAPE)) {
                    self.state = .TradingMenu;
                    fetchingStockInfo = false;
                    hasFetchedInfo = false;
                    FetchStockInfo.tickerSymbol = [_]u8{0} ** (FetchStockInfo.MAX_INPUT_CHARS + 1);
                    FetchStockInfo.letterCount = 0;
                    FetchStockInfo.framesCounter = 0;
                }
            },
            .BackToMainMenu => {
                self.app_state.* = .Menu;
            },
        }
    }

    pub fn drawState(self: TradingMenu) void {
        switch (self.state) {
            .TradingMenu => {
                self.menu.draw();
                ray.DrawText("Algorithmic Trading State", 190, 200, 20, ray.WHITE);
            },
            .FetchStockInfo => FetchStockInfo.FetchStockInfo.drawState(&fetchingStockInfo, &hasFetchedInfo),
            .BackToMainMenu => {}, // This state should immediately transition back to the main menu
        }
    }
};

fn fetchStockInfoAction() void {
    std.debug.print("Fetching stock info...\n", .{});
    if (AppState.current_app_state) |state_ptr| {
        if (state_ptr.* == .AlgorithmicTrading) {
            if (AppState.current_trading_menu) |trading_menu| {
                // set appstate to
                trading_menu.state = .FetchStockInfo;
            }
        }
    }
}

fn backToMainMenuAction() void {
    std.debug.print("Returning to main menu...\n", .{});
    if (AppState.current_app_state) |state_ptr| {
        if (state_ptr.* == .AlgorithmicTrading) {
            if (AppState.current_trading_menu) |trading_menu| {
                trading_menu.state = .BackToMainMenu;
            }
        }
    }
}
