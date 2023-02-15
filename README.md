Wasm Runtime Tests
==================

This repository contains infrastructure to test the various
WebAssembly runtimes, to see how compatible they are with the
official wasm-c-api.

How to Run Tests
----------------

Install the commands listed under the `Prerequisites` section. Then execute the
file `test_runtimes.sh`.

How it Works
------------

The script downloads the `wasm-c-api` project, which holds the example
applications we want to test. The script then downloads the various Wasm
runtimes, and builds them as a library. Then it compiles the example programs
in the `wasm-c-api` project, and links them with these libraries. The script then
executes the resulting executable, to see if the example programs work with the
runtime being tested.

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
| callback.c  | pass     | pass   |
| finalize.c  | X        | X      |
| global.c    | X        | pass   |
| hello.c     | pass     | pass   |
| hostref.c   | X        | X      |
| memory.c    | X        | pass   |
| multi.c     | pass     | pass   |
| reflect.c   | pass     | pass   |
| serialize.c | pass     | pass   |
| start.c     | X        | pass   |
| table.c     | X        | X      |
| threads.c   | pass     | X      |
| trap.c      | pass     | pass   |

