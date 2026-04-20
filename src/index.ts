import zigflareWasm from "./zigflare.wasm";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

interface WasmExports {
  memory: WebAssembly.Memory;
  alloc: (len: number) => number;
  free: (ptr: number, len: number) => void;
  greet: (namePtr: number, nameLen: number, outPtr: number, outCap: number) => number;
}

function greet(name: string): string {
  const instance = new WebAssembly.Instance(zigflareWasm);
  const wasm = instance.exports as unknown as WasmExports;

  const nameBytes = encoder.encode(name);
  const outCap = nameBytes.length + 64;

  const namePtr = wasm.alloc(nameBytes.length);
  const outPtr = wasm.alloc(outCap);
  if (namePtr === 0 || outPtr === 0) throw new Error("WASM alloc failed");

  try {
    new Uint8Array(wasm.memory.buffer, namePtr, nameBytes.length).set(nameBytes);
    const outLen = wasm.greet(namePtr, nameBytes.length, outPtr, outCap);
    if (outLen === 0) throw new Error("greet failed");
    return decoder.decode(new Uint8Array(wasm.memory.buffer, outPtr, outLen));
  } finally {
    wasm.free(namePtr, nameBytes.length);
    wasm.free(outPtr, outCap);
  }
}

export default {
  async fetch(request: Request): Promise<Response> {
    const name = new URL(request.url).searchParams.get("name") ?? "World";
    return new Response(greet(name), {
      headers: { "Content-Type": "text/plain" },
    });
  },
};
