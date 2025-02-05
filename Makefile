.PHONY: cli core test fmt clean
.DEFAULT_GOAL := cli

download-wasi-sdk:
	./install-wasi-sdk.sh

install:
	cargo install --path crates/runtime

bench: cli
	cargo bench --package=javy

check-bench:
	cargo check --package=javy --release --benches

cli:
	cargo build --package=javy --release

runtime: core
	cargo build --package=javy-runtime --release

core:
	cargo build --package=javy-core --release --target=wasm32-wasi --features=$(CORE_FEATURES) 

docs:
	cargo doc --package=javy --open && cargo doc --package=javy-core --open --target=wasm32-wasi

test-quickjs-wasm-rs:
	cargo wasi test --package=quickjs-wasm-rs --features json -- --nocapture

test-core:
	cargo wasi test --package=javy-core -- --nocapture

# Test in release mode to skip some debug assertions
# Note: to make this faster, the engine should be optimized beforehand (wasm-strip + wasm-opt).
test-cli: core
	cargo test --package=javy --release --features=$(CLI_FEATURES) -- --nocapture

test-wpt: cli
	npm install --prefix wpt && npm test --prefix wpt 

tests: test-quickjs-wasm-rs test-core test-cli test-wpt

fmt: fmt-quickjs-wasm-sys fmt-quickjs-wasm-rs fmt-core fmt-cli

fmt-quickjs-wasm-sys:
	cargo fmt --package=quickjs-wasm-sys -- --check \
		&& cargo clippy --package=quickjs-wasm-sys --target=wasm32-wasi --all-targets -- -D warnings

fmt-quickjs-wasm-rs:
	cargo fmt --package=quickjs-wasm-rs -- --check \
		&& cargo clippy --package=quickjs-wasm-rs --target=wasm32-wasi --all-targets -- -D warnings

fmt-core:
	cargo fmt --package=javy-core -- --check \
		&& cargo clippy --package=javy-core --target=wasm32-wasi --all-targets -- -D warnings

# Use `--release` on CLI clippy to align with `test-cli`.
# This reduces the size of the target directory which improves CI stability.
fmt-cli:
	cargo fmt --package=javy -- --check \
		&& cargo clippy --package=javy --release --all-targets -- -D warnings

clean: clean-wasi-sdk clean-cargo

clean-cargo:
	cargo clean

clean-wasi-sdk:
	rm -r crates/quickjs-wasm-sys/wasi-sdk 2> /dev/null || true
