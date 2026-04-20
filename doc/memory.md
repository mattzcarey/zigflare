# Memory in Zig WASM on Cloudflare Workers

Cloudflare Workers are a constrained environment. Zig gives you manual control over every allocation. No hidden allocations, no GC pauses, no surprise memory growth. Every function that allocates takes an `std.mem.Allocator` parameter — the caller decides the strategy.

## Why this matters on Workers

With Rust or C++ compiled to WASM, you get manual memory control too. But Zig makes it *explicit at every call site*:

```zig
// You always see where memory comes from
const result = try std.fmt.allocPrint(allocator, "Hello, {s}!", .{name});
defer allocator.free(result);
```

There's no global `malloc` hiding behind the scenes. If a function allocates, it says so in the signature. You can grep for every allocation in your codebase.

## How JS and WASM share memory

WASM has a single flat `memory` buffer. Both JS and Zig read/write it.

```
JS                        WASM linear memory                  Zig
──                        ──────────────────                  ───
alloc(len) ────────────►  [····allocated····]  ◄── wasm_allocator
write input ──────────►   [Zig··············]
                          call greet() ──────► reads input, allocates scratch
                          [Hello, Zig!······] ◄── writes output
read output ◄──────────   [Hello, Zig!······]
free(ptr, len) ────────►  [··················]
```

Zig exports `alloc` and `free` so JS can get pointers into WASM memory. Internally, Zig uses whatever allocator it wants for scratch work.

**One gotcha:** after any call that might grow memory (including `alloc`), existing `Uint8Array` views are detached. Always create views *after* allocating:

```typescript
// ✓ correct — view created after alloc
const ptr = wasm.alloc(1024);
new Uint8Array(wasm.memory.buffer, ptr, data.length).set(data);

// ✗ broken — view might be stale
const view = new Uint8Array(wasm.memory.buffer);
const ptr = wasm.alloc(1024);  // might grow memory, detaching view
view.set(data, ptr);            // crash
```

## Allocators available in Zig

Zig's stdlib ships several allocators. Here's what's relevant for WASM:

**`std.heap.wasm_allocator`** — the standard choice. General-purpose allocator that uses `@wasmMemoryGrow` for backing pages, then carves them up with a free list. Supports alloc, resize, and free. This is what zigflare uses.

**`std.heap.page_allocator`** — every allocation rounds up to a 64KB WASM page. Wasteful for small allocations, fine for large buffers. Pages are never returned (WASM memory only grows).

**`std.heap.ArenaAllocator`** — wraps any allocator. Individual frees are no-ops; everything is released at once on `deinit()`. Perfect for request-scoped work on Workers — allocate freely during the request, bulk-free at the end.

**`std.heap.FixedBufferAllocator`** — bump allocator over a fixed byte slice. No syscalls, no page growth. Fails with `OutOfMemory` when full. Use when you know the upper bound.

**`std.testing.allocator`** — detects leaks and double-frees. Use in tests, not production.

The key insight: because every allocating function takes an `Allocator` parameter, you can swap strategies without changing your logic. Use `wasm_allocator` in production, `testing.allocator` in tests, `ArenaAllocator` for request batches — same code, different tradeoffs.
