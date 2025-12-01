const std = @import("std");
const zglfw = @import("zglfw");
const zopengl = @import("zopengl");

const window_title = "minimal";
const window_width = 600;
const window_height = 600;
const opengl_version_major = 4;
const opengl_version_minor = 6;

fn setWindowCenter(window: *zglfw.Window) !void {
    if (zglfw.getPrimaryMonitor()) |monitor| {
        const mode = try monitor.getVideoMode();
        const x = @divTrunc(mode.width, 2) - window_width / 2;
        const y = @divTrunc(mode.height, 2) - window_height / 2;
        zglfw.setWindowPos(window, x, y);
    } else {
        return error.FailedGetPrimaryMonitor;
    }
}

pub fn main() !void {
    try zglfw.init();
    defer zglfw.terminate();

    zglfw.windowHint(.client_api, .opengl_api);
    zglfw.windowHint(.context_version_major, opengl_version_major);
    zglfw.windowHint(.context_version_minor, opengl_version_minor);
    zglfw.windowHint(.opengl_profile, .opengl_core_profile);
    zglfw.windowHint(.opengl_forward_compat, true);
    zglfw.windowHint(.doublebuffer, true);
    zglfw.windowHint(.resizable, false);

    const window = try zglfw.createWindow(window_width, window_height, window_title, null);
    defer zglfw.destroyWindow(window);

    try setWindowCenter(window);

    zglfw.makeContextCurrent(window);
    zglfw.swapInterval(1);

    try zopengl.loadCoreProfile(zglfw.getProcAddress, opengl_version_major, opengl_version_minor);

    const gl = zopengl.bindings;

    while (!window.shouldClose()) {
        zglfw.pollEvents();

        // render your things here

        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });

        window.swapBuffers();
    }
}
