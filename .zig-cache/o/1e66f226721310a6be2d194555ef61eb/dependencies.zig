pub const packages = struct {
    pub const @"122078ad3e79fb83b45b04bd30fb63aaf936c6774db60095bc6987d325cbe5743373" = struct {
        pub const build_root = "/Users/noxford/.cache/zig/p/122078ad3e79fb83b45b04bd30fb63aaf936c6774db60095bc6987d325cbe5743373";
        pub const build_zig = @import("122078ad3e79fb83b45b04bd30fb63aaf936c6774db60095bc6987d325cbe5743373");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220864a314db60a5e43df335d496c5bbe6ca82c6f2a98e9f34d3c1b00df312a79a3" = struct {
        pub const build_root = "/Users/noxford/.cache/zig/p/1220864a314db60a5e43df335d496c5bbe6ca82c6f2a98e9f34d3c1b00df312a79a3";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib", "122078ad3e79fb83b45b04bd30fb63aaf936c6774db60095bc6987d325cbe5743373" },
    .{ "raygui", "1220864a314db60a5e43df335d496c5bbe6ca82c6f2a98e9f34d3c1b00df312a79a3" },
};
