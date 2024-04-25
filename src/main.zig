const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

//const assert = @import("std").debug.assert;


const GRID_SIZE:u32 = 1000; // system size
const TOTAL_SIZE: u32 = GRID_SIZE*GRID_SIZE; // leave untouched
const CELL_SIZE: i8 = 1; //pixel size for each cell (1 is the fastest to render)
const WINDOW_SIZE: i32 = CELL_SIZE*GRID_SIZE;


// Simply inline function for indexing
inline fn IDX(i: usize,j:usize) usize {
    return ((i + GRID_SIZE)%GRID_SIZE)*GRID_SIZE + ((j+GRID_SIZE)%GRID_SIZE);
}


fn topple(i: usize, sandpile: *[TOTAL_SIZE]i8) i8 {
    sandpile[i] += -4;
    if (i > 0) {
        sandpile[i-1] += 1;
        update(i - 1, sandpile);
    }
    if (i < TOTAL_SIZE - 1) {
        sandpile[i+1] += 1;
        update(i + 1, sandpile);
    }
    if (i / GRID_SIZE > 0) {
        sandpile[i-GRID_SIZE] += 1;
        update(i - GRID_SIZE, sandpile);
    }
    if (i / GRID_SIZE < GRID_SIZE-1) {
        sandpile[i+GRID_SIZE] += 1;
        update(i + GRID_SIZE, sandpile);
    }
    return sandpile[i];
}

fn update(i: usize, sandpile: *[TOTAL_SIZE]i8) void {
    sandpile[i] = switch (sandpile[i]){
        0=> 0,
        1=> 1,
        2=> 2,
        3=> 3,
        else=> topple(i, sandpile),
    };
}


pub fn main() !void {
    // SDL initialization stuff
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

    // Creating our sandpile & texture-buffer for display
    var textureBuffer: [TOTAL_SIZE]u32 = undefined;
    var sandpile: [TOTAL_SIZE]i8 = undefined;

    for (0..TOTAL_SIZE) |i| {
        sandpile[i] = 0;
        textureBuffer[i] = 0x000000;
    }

    // Defining our print
    //const stdout = std.io.getStdOut().writer();
    // Defining our texture
    const theTexture: ?*c.SDL_Texture = c.SDL_CreateTexture(renderer, c.SDL_PIXELFORMAT_ARGB8888, c.SDL_TEXTUREACCESS_STREAMING, GRID_SIZE, GRID_SIZE);

    const centerval: u32 = (GRID_SIZE/2)*GRID_SIZE + GRID_SIZE/2;

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
        //const start1 = try std.time.Instant.now();
        render(&sandpile, &textureBuffer, theTexture);
        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderCopy(renderer, theTexture, null, null);
        _ = c.SDL_RenderPresent(renderer);
        //const end1 = try std.time.Instant.now();
        //const elapsed1: f64 = @floatFromInt(end1.since(start1));
        //try stdout.print("Render Time = {}ms \n", .{elapsed1 / std.time.ns_per_ms});
        //const start2 = try std.time.Instant.now();
        sandpile[centerval] += 4;
        update(centerval, &sandpile);
        //const end2 = try std.time.Instant.now();
        //const elapsed2: f64 = @floatFromInt(end2.since(start2));
        //try stdout.print("Update Time = {}ms \n", .{elapsed2 / std.time.ns_per_ms});
        counter += 1;
        //try stdout.print("Time {} \n", .{counter});
    }
}


// Defining our render function
fn render(sandpile: *[TOTAL_SIZE]i8, textureBuffer: *[TOTAL_SIZE]u32, theTexture: ?*c.SDL_Texture) void {
    for (0..GRID_SIZE) |i| {
        for (0..GRID_SIZE) |j| {
            const index: usize = IDX(i, j);
            const state: i8 = sandpile[index];
            textureBuffer[index] = switch (state) {
                0=> 0x000000,
                1=> 0xff0000,
                2=> 0x00ff00,
                3=> 0x0000ff,
                else => unreachable,
            };
        }
    }
    _ = c.SDL_UpdateTexture(theTexture, null, textureBuffer,  GRID_SIZE*@sizeOf(u32));
}
