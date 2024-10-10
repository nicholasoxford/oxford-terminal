const objc = @import("zig-objc");
const std = @import("std");
pub fn macosVersionAtLeast(major: i64, minor: i64, patch: i64) !bool {
    // Get the objc class from the runtime
    const metalInfo = objc.getClass("metal").?;
    const NSProcessInfo = objc.getClass("NSProcessInfo").?;

    std.log.debug("major: {d}, minor: {d}, patch: {d}", .{ major, minor, patch });
    std.log.debug("NSProcessInfo: {any}", .{NSProcessInfo});
    // Call a class method with no arguments that returns another objc object.
    const info = NSProcessInfo.msgSend(objc.Object, "processInfo", .{});

    const device = metalInfo.msgSend(objc.Object, "MTLCreateSystemDefaultDevice", .{});
    std.log.debug("device: {any}", .{device});
    // return true;
    // Call an instance method that returns a boolean and takes a single
    // argument.
    return info.msgSend(bool, "isOperatingSystemAtLeastVersion:", .{
        NSOperatingSystemVersion{ .major = major, .minor = minor, .patch = patch },
    });
}

/// This extern struct matches the Cocoa headers for layout.
const NSOperatingSystemVersion = extern struct {
    major: i64,
    minor: i64,
    patch: i64,
};
