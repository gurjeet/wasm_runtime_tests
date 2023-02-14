Wasm Runtime Tests
==================

This repository contains infrastructure to test the various
WebAssembly runtimes, to see how compatible they are with the
official wasm-c-api.

How to Run Tests
----------------

For now, place the `test_runtimes.sh` file in a Git clone of the
wasm-c-api project, and then execute it.

The script will download the various Wasm runtimes, build them
as a library. Then it compiles the wasm-c-api examples, and
links them with this library. The script then executes the
resulting executable, to see if the example works with the
runtime being tested.
