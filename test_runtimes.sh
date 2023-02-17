
set -e # Exit on error
set -u # Error on referencing undefined variables

# We require Bash version 4 or above
MIN_BASH_VERSION=4
if [[ "$BASH_VERSINFO" < "$MIN_BASH_VERSION" ]]; then
	echo Bash version "$MIN_BASH_VERSION", or greater, needed. >&2
	exit 1
fi

# We'll do all our work in the directory where the script is
# being executed.
ROOT="$(pwd)"
CAPI_ROOT="$ROOT/WASM_C_API"

# TODO: Consider using Git Submodule feature, instead of cloning
# repositories using `git clone`.

function main()
(
	# We need a C compiler to run our tests
	ensure_command_exists cc
	# We need Git to download the code
	ensure_command_exists git

	info "Downloading wasm-c-api repository"
	download_wasm_c_api

	for runtime in wasmtime wasmer wasmedge; do
		if [[ "$runtime" == "wasmedge" ]]; then
			notice "$runtime tests being skipped; these tests are not implemented, yet."
			continue;
		fi

		# Call the runtime-specific functions to do the chores.
		info "Processing $runtime"
		${runtime}_check_prerequisites
		${runtime}_clone_repo
		${runtime}_build_runtime
		${runtime}_run_tests
	done
)

function info()		( echo "INFO: $@"	>&1 )
function notice()	( echo "NOTICE: $@"	>&1 )
function warning()	( echo "WARNING: $@">&2 )
function error()	( echo "ERROR: $@"	>&2 )
function fatal() (
    local exitCode="$1"
    shift
    echo "FATAL: $@" >&2
    exit "$exitCode"
)

function ensure_command_exists()
(
	( command -V "$1" 2>&1 >/dev/null ) \
		|| fatal 1 "Command not found: $1"
)

function download_wasm_c_api()
(
	([[ -e "$CAPI_ROOT"/.git ]] && info "Repository already cloned") \
	|| ( info "Clonig repository" \
		&& git clone --depth 1 https://github.com/WebAssembly/wasm-c-api.git "$CAPI_ROOT")
)

### Functions for the Wasmtime runtime
function wasmtime_check_prerequisites()
(
	ensure_command_exists cargo
)

function wasmtime_clone_repo()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmtime

	([[ -e "$RUNTIME_ROOT"/.git ]] && info "Repository already cloned") \
	|| (info "cloning repository" \
		&& git clone --depth 1 https://github.com/bytecodealliance/wasmtime.git "$RUNTIME_ROOT" \
		&& cd "$RUNTIME_ROOT" \
		&& git submodule update --init )
)

function wasmtime_build_runtime()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmtime
	cd "$RUNTIME_ROOT"

	# Instructions: https://docs.wasmtime.dev/contributing-building.html
	cargo build --release --manifest-path crates/c-api/Cargo.toml
)

function wasmtime_run_tests()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmtime

	cd "$CAPI_ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$CAPI_ROOT"/include/ "$RUNTIME_ROOT"/target/release/libwasmtime.a -lpthread -ldl -lm -o a.out >/dev/null 2>&1 \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

### Functions for the Wasmer runtime
function wasmer_check_prerequisites()
(
	ensure_command_exists cargo
	ensure_command_exists make
)

function wasmer_clone_repo()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmer

	([[ -e "$RUNTIME_ROOT"/.git ]] && info "Repository already cloned") \
	|| (info "cloning repository" \
		&& git clone --depth 1 https://github.com/wasmerio/wasmer.git "$RUNTIME_ROOT" )
)

function wasmer_build_runtime()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmer
	cd "$RUNTIME_ROOT"

	# Instructions: https://docs.wasmer.io/ecosystem/wasmer/building-from-source
	make build-capi
)

function wasmer_run_tests()
(
	local RUNTIME_ROOT="$ROOT"/runtimes/wasmer

	cd "$CAPI_ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$CAPI_ROOT"/include/ "$RUNTIME_ROOT"/target/release/libwasmer.a -lpthread -ldl -lm -o a.out >/dev/null 2>&1 \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

# Run the main function
main
