Wasm Runtime Tests
==================

This repository contains infrastructure to test the various
WebAssembly runtimes, to see how compatible they are with the
official [wasm-c-api][].

[wasm-c-api]: https://github.com/WebAssembly/wasm-c-api

How to Run Tests
----------------

Install the commands listed under the [Prerequisites](#prerequisites) section.
Then execute the file `test_runtimes.sh`.

How it Works
------------

The [wasm-c-api][] project provides the official C API for WebAssembly
runtimes. It does so by publishing the file `wasm.h`. This project also
provides some example programs to demonstrate the features of WebAssembly, and
also demonstrate how to embed a WebAssembly runtime in C programs.

The `test_runtimes.sh` script downloads the wasm-c-api code. For each
WebAssembly runtime, it then downloads code of the runtime, and compiles the
runtime into a library. It then builds the example programs provided by the
wasm-c-api project. To build the examples, the script uses the `wasm.h` file
published by the wasm-c-api project, and the library from the runtime. It
finally runs the resulting executable, to determine if the example works
successfully with the runtime under test.

Prerequisites
-------------

1. Git
2. Make
3. Rust and Cargo; commands from the Rust ecosystem.
4. A C compiler (script invokes it using `cc` command).

Compatibility Status
--------------------

Legend: X => fail.

| Program     | Wasmtime | Wasmer |
|-------------|----------|--------|
| callback.c  |     pass |   pass |
| finalize.c  |        X |      X |
| global.c    |        X |   pass |
| hello.c     |     pass |   pass |
| hostref.c   |        X |      X |
| memory.c    |        X |   pass |
| multi.c     |     pass |   pass |
| reflect.c   |     pass |   pass |
| serialize.c |     pass |   pass |
| start.c     |        X |   pass |
| table.c     |        X |      X |
| threads.c   |     pass |      X |
| trap.c      |     pass |   pass |

