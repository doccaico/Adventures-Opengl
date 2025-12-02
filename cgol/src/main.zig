const builtin = @import("builtin");
const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const window_title = "cgol";
const window_width = 600;
const window_height = 600;
const opengl_version_major = 4;
const opengl_version_minor = 6;

const max_fps = 15.0;
const frame_time = 1.0 / max_fps;

const cell_size = 3;
const board_width = window_width / cell_size;
const board_height = window_height / cell_size;
const live_cells = board_width * 0.35; // the number live cells in width
comptime {
    std.debug.assert(window_width / board_width == window_height / board_height);
}

const Cell = enum(u8) { dead = 0, alive = 1 };

var board: [board_height + 2][board_width + 2]Cell = .{.{.dead} ** (board_width + 2)} ** (board_height + 2);

fn initBoard() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var y: usize = 1;
    var x: usize = 1;
    while (y < board_height + 1) : (y += 1) {
        while (x < live_cells + 1) : (x += 1) {
            board[y][x] = .alive;
        }
        rand.shuffle(Cell, board[y][1 .. board_width + 1]);
        x = 1;
    }
}

fn renderBoard() void {
    var y: usize = 1;
    var x: usize = 1;
    while (y < board_height + 1) : (y += 1) {
        while (x < board_width + 1) : (x += 1) {
            if (board[y][x] == .alive) {
                // zig fmt: off
                gl.viewport(
                    cell_size * (@as(c_int, @intCast(x)) - 1) ,
                    window_height - (cell_size * @as(c_int, @intCast(y))),
                    cell_size,
                    cell_size);
                // zig fmt: on
                gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
            }
        }
        x = 1;
    }
}

fn updateBoard() void {
    var neighbors: [board_height + 2][board_width + 2]u8 = undefined;

    var y: usize = 1;
    var x: usize = 1;
    while (y < board_height + 1) : (y += 1) {
        while (x < board_width + 1) : (x += 1) {
            neighbors[y][x] = countNeighbors(y, x);
        }
        x = 1;
    }

    y = 1;
    x = 1;
    while (y < board_height + 1) : (y += 1) {
        while (x < board_width + 1) : (x += 1) {
            switch (neighbors[y][x]) {
                2 => {},
                3 => board[y][x] = .alive,
                else => board[y][x] = .dead,
            }
        }
        x = 1;
    }
}

inline fn countNeighbors(y: u64, x: u64) u8 {
    const a = (@intFromEnum(board[y - 1][x - 1]) +
        // top-middle
        @intFromEnum(board[y - 1][x]) +
        // top-right
        @intFromEnum(board[y - 1][x + 1]) +
        // left
        @intFromEnum(board[y][x - 1]) +
        // right
        @intFromEnum(board[y][x + 1]) +
        // bottom-left
        @intFromEnum(board[y + 1][x - 1]) +
        // bottom-middle
        @intFromEnum(board[y + 1][x]) +
        // bottom-right
        @intFromEnum(board[y + 1][x + 1]));

    _ = a;
    // std.debug.print("{any}\n", .{a});
    // zig fmt: off
    return (
        // top-left
        @intFromEnum(board[y - 1][x - 1]) +
        // top-middle
        @intFromEnum(board[y - 1][x]) +
        // top-right
        @intFromEnum(board[y - 1][x + 1]) +
        // left
        @intFromEnum(board[y][x - 1]) +
        // right
        @intFromEnum(board[y][x + 1]) +
        // bottom-left
        @intFromEnum(board[y + 1][x - 1]) +
        // bottom-middle
        @intFromEnum(board[y + 1][x]) +
        // bottom-right
        @intFromEnum(board[y + 1][x + 1]));
    // zig fmt: on
}

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

    // const gl = opengl.bindings;

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

    try initBoard();

    var last_time = glfw.getTime();
    var last_update_time = last_time;
    var accumulated_time: f64 = 0.0;

    while (!glfw.windowShouldClose(window)) {
        const current_time = glfw.getTime();
        const dt = current_time - last_time;
        last_time = current_time;
        accumulated_time += dt;

        // input
        glfw.pollEvents();
        if (glfw.getKey(window, .escape) == .press) {
            glfw.setWindowShouldClose(window, true);
        }

        if (accumulated_time >= frame_time) {
            // const update_dt = current_time - last_update_time;
            last_update_time = current_time;
            accumulated_time = 0.0;

            // update
            updateBoard();
            // update(update_dt);
            // std.debug.print("{any}\n", .{update_dt});

            // render
            gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
            // left bottom
            renderBoard();

            // std.debug.print("{any}\n", .{last_update_time});
            glfw.swapBuffers(window);
        }
    }
}
