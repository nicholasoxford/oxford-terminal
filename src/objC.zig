const objc = @import("zig-objc");
const std = @import("std");

pub fn checkMacOSAndMetal(major: i64, minor: i64, patch: i64) !bool {
    const os_version_ok = try checkMacOSVersion(major, minor, patch);
    if (!os_version_ok) {
        std.log.debug("macOS version is not compatible", .{});
        return false;
    }

    const metal_ok = try checkMetalCompatibility();
    if (!metal_ok) {
        std.log.debug("Metal is not supported on this system", .{});
        return false;
    }

    std.log.debug("System is compatible with required macOS version and supports Metal", .{});
    return true;
}

fn checkMacOSVersion(major: i64, minor: i64, patch: i64) !bool {
    const NSProcessInfo = objc.getClass("NSProcessInfo").?;

    std.log.debug("major: {d}, minor: {d}, patch: {d}", .{ major, minor, patch });
    std.log.debug("NSProcessInfo: {any}", .{NSProcessInfo});

    const info = NSProcessInfo.msgSend(objc.Object, "processInfo", .{});

    const result = info.msgSend(bool, "isOperatingSystemAtLeastVersion:", .{
        NSOperatingSystemVersion{ .major = major, .minor = minor, .patch = patch },
    });

    return result;
}

fn checkMetalCompatibility() !bool {
    const metalDevice = objc.Object.fromId(MTLCreateSystemDefaultDevice());
    std.log.debug("metalDevice: {any}", .{metalDevice});
    if (metalDevice.value == null) {
        return false;
    }

    const queue = metalDevice.msgSend(objc.Object, objc.sel("newCommandQueue"), .{});
    std.log.debug("queue: {any}", .{queue});

    if (queue.value == null) {
        std.log.debug("Failed to create command queue", .{});
        _ = metalDevice.msgSend(void, objc.sel("release"), .{});
        return false;
    }

    // Create a Metal layer and perform a simple rendering test
    const CAMetalLayerClass = objc.getClass("CAMetalLayer").?;
    const layer = CAMetalLayerClass.msgSend(objc.Object, objc.sel("layer"), .{});
    _ = layer.msgSend(void, objc.sel("setDevice:"), .{metalDevice});
    _ = layer.msgSend(void, objc.sel("setPixelFormat:"), .{MTLPixelFormatBGRA8Unorm});
    _ = layer.msgSend(void, objc.sel("setFrame:"), .{CGRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = 100, .height = 100 } }});

    const drawable = layer.msgSend(objc.Object, objc.sel("nextDrawable"), .{});
    if (drawable.value != null) {
        const commandBuffer = queue.msgSend(objc.Object, objc.sel("commandBuffer"), .{});
        const texture = drawable.msgSend(objc.Object, objc.sel("texture"), .{});

        const renderPassDescriptor = objc.getClass("MTLRenderPassDescriptor").?.msgSend(objc.Object, objc.sel("renderPassDescriptor"), .{});
        const colorAttachment = renderPassDescriptor.msgSend(objc.Object, objc.sel("colorAttachments"), .{}).msgSend(objc.Object, objc.sel("objectAtIndexedSubscript:"), .{@as(c_longlong, 0)});
        _ = colorAttachment.msgSend(void, objc.sel("setTexture:"), .{texture});
        _ = colorAttachment.msgSend(void, objc.sel("setLoadAction:"), .{MTLLoadActionClear});
        _ = colorAttachment.msgSend(void, objc.sel("setClearColor:"), .{MTLClearColor{ .red = 1.0, .green = 0.0, .blue = 0.0, .alpha = 1.0 }});

        const encoder = commandBuffer.msgSend(objc.Object, objc.sel("renderCommandEncoderWithDescriptor:"), .{renderPassDescriptor});
        _ = encoder.msgSend(void, objc.sel("endEncoding"), .{});

        _ = commandBuffer.msgSend(void, objc.sel("presentDrawable:"), .{drawable});
        _ = commandBuffer.msgSend(void, objc.sel("commit"), .{});

        std.log.debug("Metal rendering completed successfully", .{});
    } else {
        std.log.debug("Failed to get next drawable", .{});
    }

    // Release resources
    _ = queue.msgSend(void, objc.sel("release"), .{});
    _ = metalDevice.msgSend(void, objc.sel("release"), .{});

    return true;
}

/// This extern struct matches the Cocoa headers for layout.
const NSOperatingSystemVersion = extern struct {
    major: i64,
    minor: i64,
    patch: i64,
};

extern "c" fn MTLCreateSystemDefaultDevice() ?*anyopaque;

// Add these constants and structs
const MTLPixelFormatBGRA8Unorm: c_uint = 80;
const MTLLoadActionClear: c_uint = 2;

const CGRect = extern struct {
    origin: CGPoint,
    size: CGSize,
};

const CGPoint = extern struct {
    x: f64,
    y: f64,
};

const CGSize = extern struct {
    width: f64,
    height: f64,
};

const MTLClearColor = extern struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

// Add these constants
const NSWindowStyleMaskTitled: c_ulong = 1;
const NSWindowStyleMaskClosable: c_ulong = 2;
const NSWindowStyleMaskMiniaturizable: c_ulong = 4;
const NSWindowStyleMaskResizable: c_ulong = 8;
const NSBackingStoreBuffered: c_ulong = 2;

const MTLSize = extern struct {
    width: c_ulong,
    height: c_ulong,
    depth: c_ulong,
};

const MTLPipelineOptionNone: c_uint = 0;
const MTLResourceStorageModeShared: c_uint = 0;
