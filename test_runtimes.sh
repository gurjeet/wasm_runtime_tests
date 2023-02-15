
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

	for engine in wasmtime wasmer wasmedge; do
		if [[ "$engine" == "wasmedge" ]]; then
			notice "$engine tests being skipped; these tests are not implemented, yet."
			continue;
		fi

		# Call the engine-specific functions to do the chores.
		info "Processing $engine"
		${engine}_check_prerequisites
		${engine}_clone_repo
		${engine}_build_engine
		${engine}_run_tests
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

### Functions for the Wasmtime engine
function wasmtime_check_prerequisites()
(
	ensure_command_exists cargo
)

function wasmtime_clone_repo()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmtime

	([[ -e "$ENGINE_ROOT"/.git ]] && info "Repository already cloned") \
	|| (info "cloning repository" \
		&& git clone --depth 1 https://github.com/bytecodealliance/wasmtime.git "$ENGINE_ROOT" \
		&& cd "$ENGINE_ROOT" \
		&& git submodule update --init )
)

function wasmtime_build_engine()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmtime
	cd "$ENGINE_ROOT"

	# Instructions: https://docs.wasmtime.dev/contributing-building.html
	cargo build --release --manifest-path crates/c-api/Cargo.toml
)

function wasmtime_run_tests()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmtime

	cd "$CAPI_ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$CAPI_ROOT"/include/ "$ENGINE_ROOT"/target/release/libwasmtime.a -lpthread -ldl -lm -o a.out >/dev/null 2>&1 \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

### Functions for the Wasmer engine
function wasmer_check_prerequisites()
(
	ensure_command_exists cargo
	ensure_command_exists make
)

function wasmer_clone_repo()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmer

	([[ -e "$ENGINE_ROOT"/.git ]] && info "Repository already cloned") \
	|| (info "cloning repository" \
		&& git clone --depth 1 https://github.com/wasmerio/wasmer.git "$ENGINE_ROOT" )
)

function wasmer_build_engine()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmer
	cd "$ENGINE_ROOT"

	# Instructions: https://docs.wasmer.io/ecosystem/wasmer/building-from-source
	make build-capi
)

function wasmer_run_tests()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmer

	cd "$CAPI_ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$CAPI_ROOT"/include/ "$ENGINE_ROOT"/target/release/libwasmer.a -lpthread -ldl -lm -o a.out >/dev/null 2>&1 \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

# Run the main function
main
