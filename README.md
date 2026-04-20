# zigflare

Hello World: Zig → WASM → Cloudflare Workers.

```
GET /?name=Zig  →  "Hello, Zig!"
GET /           →  "Hello, World!"
```

## Quick start

```bash
npm install
npm run build:wasm
npm run dev
```

## How it works

Zig compiles to a ~4KB `.wasm` module. The Worker loads it, allocates input/output buffers in WASM memory, calls the Zig `greet` function, and reads the result back.

See [doc/memory.md](doc/memory.md) for how JS↔WASM memory sharing works.

## Commands

| Command | What |
|---------|------|
| `npm run build:wasm` | Compile Zig → WASM |
| `npm run dev` | Build + local dev server |
| `npm run deploy` | Build + deploy to Cloudflare |

## Prerequisites

- [Zig 0.16.0](https://ziglang.org/download/)
- [Node.js](https://nodejs.org/)

## License

MIT
