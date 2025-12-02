const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const window_title = "rectangle";
const window_width = 600;
const window_height = 600;
const opengl_version_major = 4;
const opengl_version_minor = 6;

fn setWindowCenter(window: *glfw.Window) !void {
    if (glfw.getPrimaryMonitor()) |monitor| {
        const mode = try monitor.getVideoMode();
        const x = @divTrunc(mode.width, 2) - window_width / 2;
        const y = @divTrunc(mode.height, 2) - window_height / 2;
        glfw.setWindowPos(window, x, y);
    } else {
        return error.FailedGetPrimaryMonitor;
    }
}

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .opengl_api);
    glfw.windowHint(.context_version_major, opengl_version_major);
    glfw.windowHint(.context_version_minor, opengl_version_minor);
    glfw.windowHint(.opengl_profile, .opengl_core_profile);
    glfw.windowHint(.opengl_forward_compat, true);
    glfw.windowHint(.doublebuffer, true);
    glfw.windowHint(.resizable, false);

    const window = try glfw.createWindow(window_width, window_height, window_title, null);
    defer glfw.destroyWindow(window);

    try setWindowCenter(window);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    try zopengl.loadCoreProfile(glfw.getProcAddress, opengl_version_major, opengl_version_minor);

    // zig fmt: off
    // const vertices = [_]f32{
    //     0.5,  0.5, 0.0,
    //     0.5, -0.5, 0.0,
    //    -0.5,  0.5, 0.0,
    //    -0.5, -0.5, 0.0,
    // };
    const vertices = [_]f32{
        1.0,  1.0, 0.0,
        1.0, -1.0, 0.0,
       -1.0,  1.0, 0.0,
       -1.0, -1.0, 0.0,
    };
    // zig fmt: on

    var vbo: gl.Uint = undefined;
    gl.genBuffers(1, &vbo);
    defer gl.deleteBuffers(1, &vbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, gl.STATIC_DRAW);

    var vao: gl.Uint = undefined;
    gl.genVertexArrays(1, &vao);
    defer gl.deleteVertexArrays(1, &vao);
    gl.bindVertexArray(vao);
    gl.enableVertexAttribArray(0);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, null);

    const vertex_shader =
        \\#version 460 core
        \\
        \\in vec3 vp;
        \\
        \\void main() {
        \\  gl_Position = vec4(vp, 1.0);
        \\}
    ;

    const fragment_shader =
        \\#version 460 core
        \\
        \\out vec4 frag_color;
        \\
        \\void main() {
        \\  frag_color = vec4(1.0, 0.5, 0.2, 1.0);
        \\}
    ;

    const vs = blk: {
        const vs: gl.Uint = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vs, 1, &[_][*:0]const u8{vertex_shader}, null);
        gl.compileShader(vs);
        var success: gl.Int = undefined;
        gl.getShaderiv(vs, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) return error.FailedVertexCompile;
        break :blk vs;
    };
    defer gl.deleteShader(vs);

    const fs = blk: {
        const fs: gl.Uint = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fs, 1, &[_][*:0]const u8{fragment_shader}, null);
        gl.compileShader(fs);
        var success: gl.Int = undefined;
        gl.getShaderiv(fs, gl.COMPILE_STATUS, &success);
        if (success == gl.FALSE) return error.FailedFragmentCompile;
        break :blk fs;
    };
    defer gl.deleteShader(fs);

    const shader_program = blk: {
        const shader_program: gl.Uint = gl.createProgram();
        gl.attachShader(shader_program, vs);
        gl.attachShader(shader_program, fs);
        gl.linkProgram(shader_program);
        var success: gl.Int = undefined;
        gl.getShaderiv(vs, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) return error.FailedShaderLink;
        break :blk shader_program;
    };
    defer gl.deleteProgram(shader_program);

    gl.useProgram(shader_program);

    // *Wireframe mode*
    // To draw your triangles in wireframe mode, you can configure how OpenGL draws its primitives via gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE). The first argument says we want to apply it to the front and back of all triangles and the second line tells us to draw them as lines. Any subsequent drawing calls will render the triangles in wireframe mode until we set it back to its default using gl.polygonMode(gl.FRONT_AND_BACK, gl.FILL).
    // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    while (!glfw.windowShouldClose(window)) {
        // input
        glfw.pollEvents();
        if (glfw.getKey(window, .escape) == .press) {
            glfw.setWindowShouldClose(window, true);
        }

        // render
        gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
        // left bottom
        gl.viewport(0, 0, window_width / 2, window_height / 2);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

        glfw.swapBuffers(window);
    }
}
