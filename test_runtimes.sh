
set -e # Exit on error
set -u # Error on referencing undefined variables

# We require Bash version 4 or above
MIN_BASH_VERSION=4
if [[ "$BASH_VERSINFO" < "$MIN_BASH_VERSION" ]]; then
	echo Bash version "$MIN_BASH_VERSION", or greater, needed. >&2
	exit 1
fi

ROOT="$(pwd)"

function main()
(
	# We need a C compiler to run our tests
	check_command_exists cc

	for engine in wasmtime wasmer wasmedge; do
		if [[ "$engine" == "wasmedge" ]]; then
			echo "$engine tests being skipped; these tests are not implemented, yet." >&2
			continue;
		fi

		# Call the engine-specific functions to do the chores.
		${engine}_check_prerequisites
		${engine}_clone_repo
		${engine}_build_engine
		${engine}_run_tests
	done
)

function check_command_exists()
(
	( command -V "$1" 2>&1 >/dev/null ) \
		|| (echo "Command not found: $1" >&2 && exit 1)
)

### Functions for the Wasmtime engine
function wasmtime_check_prerequisites()
(
	check_command_exists cargo
)

function wasmtime_clone_repo()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmtime

	([[ -d "$ENGINE_ROOT"/.git ]] && echo Repository already cloned) \
	|| (echo cloning repository \
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

	cd "$ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$ROOT"/include/ "$ENGINE_ROOT"/target/release/libwasmtime.a -lpthread -ldl -lm -o a.out 2>&1 >/dev/null \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

### Functions for the Wasmer engine
function wasmer_check_prerequisites()
(
	check_command_exists cargo
	check_command_exists make
)

function wasmer_clone_repo()
(
	local ENGINE_ROOT="$ROOT"/engines/wasmer

	([[ -d "$ENGINE_ROOT"/.git ]] && echo Repository already cloned) \
	|| (echo cloning repository \
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

	cd "$ROOT"/example/

	for F in *.c; do
		echo -n "Testing $F ... "
		(cc "$F" -I "$ROOT"/include/ "$ENGINE_ROOT"/target/release/libwasmer.a -lpthread -ldl -lm -o a.out 2>&1 >/dev/null \
			&& ./a.out 2>&1 >/dev/null && echo ok) \
		|| echo failed;
	done
)

# Run the main function
main
