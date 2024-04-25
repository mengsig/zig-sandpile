const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

//const assert = @import("std").debug.assert;


const GRID_SIZE:u32 = 2000;
const TOTAL_SIZE: u32 = GRID_SIZE*GRID_SIZE;
const CELL_SIZE: i8 = 1;
const WINDOW_SIZE: i32 = CELL_SIZE*GRID_SIZE;
const p: f16 = 0.0005; // The probability of a tree recovering from burnt --> green
const f: f16 = 0.000003; // The probability of a green cell to randomly go on fire.



// Creating a random number generator
var prng = std.rand.DefaultPrng.init(0);
const randomGenerator = prng.random();


// Simply inline function for indexing
inline fn IDX(i: usize,j:usize) usize {
    return ((i + GRID_SIZE)%GRID_SIZE)*GRID_SIZE + ((j+GRID_SIZE)%GRID_SIZE);
}


fn burn(i: usize, forest: *[TOTAL_SIZE]u2) u2 {
    if (i > 0) {
        if (forest[i-1] == 2) return 2;
    }
    if (i < TOTAL_SIZE - 1) {
        if (forest[i+1] == 2) return 2;
    }
    if (i / GRID_SIZE > 0) {
        if (forest[i-GRID_SIZE] == 2) return 2;
    }
    if (i / GRID_SIZE < GRID_SIZE-1) {
        if (forest[i+GRID_SIZE] == 2) return 2;
    }
    if (randomGenerator.float(f32) < f) return 2;
    return 1;
}

fn update(i: usize, forest: *[TOTAL_SIZE]u2) u2 {
    const newVal: u2 = switch (forest[i]){
        0=> @intFromBool(randomGenerator.float(f32) < p),
        1=> burn(i, forest),
        2=> 0,
        else=> unreachable,
    };
    return newVal;
}

fn systemUpdate(forest: *[TOTAL_SIZE]u2) void {
    var oldForest: [TOTAL_SIZE]u2 = undefined;
    @memcpy(&oldForest, forest);
    for (0..TOTAL_SIZE) |i| {
        forest[i] = update(i, &oldForest);
    }
}






pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("My Game Window", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, WINDOW_SIZE, WINDOW_SIZE, c.SDL_WINDOW_OPENGL) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // Creating our forest & texture-buffer for display
    var textureBuffer: [TOTAL_SIZE]u32 = undefined;
    var forest: [TOTAL_SIZE]u2 = undefined;

    for (0..TOTAL_SIZE) |i| {
        forest[i] = @intFromBool(randomGenerator.boolean());
        if (forest[i] == 0) {
            textureBuffer[i] = 0x000000;
        }
        else {
            textureBuffer[i] = 0x00FF00;
        }
    }

    // Defining our print
    const stdout = std.io.getStdOut().writer();
    // Defining our texture
    const theTexture: ?*c.SDL_Texture = c.SDL_CreateTexture(renderer, c.SDL_PIXELFORMAT_ARGB8888, c.SDL_TEXTUREACCESS_STREAMING, GRID_SIZE, GRID_SIZE);

    var quit = false;
    var counter: u64 = 0;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        const start1 = try std.time.Instant.now();
        render(&forest, &textureBuffer, theTexture);
        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderCopy(renderer, theTexture, null, null);
        _ = c.SDL_RenderPresent(renderer);
        const end1 = try std.time.Instant.now();
        const elapsed1: f64 = @floatFromInt(end1.since(start1));
        try stdout.print("Render Time = {}ms \n", .{elapsed1 / std.time.ns_per_ms});
        const start2 = try std.time.Instant.now();
        systemUpdate(&forest);
        const end2 = try std.time.Instant.now();
        const elapsed2: f64 = @floatFromInt(end2.since(start2));
        try stdout.print("Update Time = {}ms \n", .{elapsed2 / std.time.ns_per_ms});
        counter += 1;
        try stdout.print("Time {} \n", .{counter});
    }
}


// Defining our render function
fn render(forest: *[TOTAL_SIZE]u2, textureBuffer: *[TOTAL_SIZE]u32, theTexture: ?*c.SDL_Texture) void {
    for (0..GRID_SIZE) |i| {
        for (0..GRID_SIZE) |j| {
            const index: usize = IDX(i, j);
            const state: u2 = forest[index];
            textureBuffer[index] = switch (state) {
                0=> 0x000000,
                1=> 0x00FF00,
                2=> 0xFF0000,
                else => unreachable,
            };
        }
    }
    _ = c.SDL_UpdateTexture(theTexture, null, textureBuffer,  GRID_SIZE*@sizeOf(u32));
}
