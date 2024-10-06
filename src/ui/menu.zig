const std = @import("std");
const ray = @import("../raylib.zig");
const AppState = @import("../app_state.zig");

pub const MenuItem = struct {
    label: [*:0]const u8, // Null-terminated C string
    action: *const fn () void,
};

pub const Menu = struct {
    items: []const MenuItem,
    selected_index: usize = 0,
    font_size: c_int,
    base_x: c_int,
    base_y: c_int,

    pub fn handleInput(self: *Menu) void {
        const mouse_pos = ray.GetMousePosition();
        var y: c_int = self.base_y;
        var found_hover = false;

        for (self.items, 0..) |item, index| {
            const text_width = ray.MeasureText(item.label, self.font_size);
            const text_height = self.font_size;
            const rect = ray.Rectangle{
                .x = @as(f32, @floatFromInt(self.base_x)),
                .y = @as(f32, @floatFromInt(y)),
                .width = @as(f32, @floatFromInt(text_width)),
                .height = @as(f32, @floatFromInt(text_height)),
            };

            if (ray.CheckCollisionPointRec(mouse_pos, rect)) {
                self.selected_index = index;
                found_hover = true;
                if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
                    item.action();
                }
            }

            y += self.font_size + 10;
        }

        if (!found_hover) {
            if (ray.IsKeyPressed(ray.KEY_UP)) {
                if (self.selected_index > 0) {
                    self.selected_index -= 1;
                }
            }
            if (ray.IsKeyPressed(ray.KEY_DOWN)) {
                if (self.selected_index < self.items.len - 1) {
                    self.selected_index += 1;
                }
            }
            if (ray.IsKeyPressed(ray.KEY_ENTER)) {
                self.items[self.selected_index].action();
            }
        }
    }

    pub fn draw(self: Menu) void {
        var y: c_int = self.base_y;
        for (self.items, 0..) |item, index| {
            const color = if (index == self.selected_index) ray.GREEN else ray.WHITE;
            ray.DrawText(item.label, self.base_x, y, self.font_size, color);
            y += self.font_size + 10;
        }
    }
};
