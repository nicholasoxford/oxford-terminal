const TradingMenu = @import("algorithmic_trading/trading_menu.zig").TradingMenu;

pub const AppState = enum {
    Menu,
    AlgorithmicTrading,
    NeuralNetworks,
    LeetcodeNotes,
    Exit, // Added Exit state
};

// Global pointer to the current application state
pub var current_app_state: ?*AppState = null;

pub const MenuOption = enum {
    FirstOption,
    SecondOption,
    ThirdOption,
};

// Global pointer to the current TradingMenu instance
pub var current_trading_menu: ?*TradingMenu = null;
