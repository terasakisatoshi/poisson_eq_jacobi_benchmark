#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RESULT_FILE="$ROOT_DIR/benchmark/RESULT.md"
LOG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/poisson-benchmark.XXXXXX")

device_name() {
    if command -v sysctl >/dev/null 2>&1; then
        sysctl -n machdep.cpu.brand_string 2>/dev/null && return
        sysctl -n hw.model 2>/dev/null && return
    fi
    if command -v lscpu >/dev/null 2>&1; then
        lscpu | awk -F: '/^[[:space:]]*Model name:/ {
            value = $2
            sub(/^[[:space:]]+/, "", value)
            print value
            exit
        }'
        return
    fi
    uname -m
}

DEVICE_NAME=$(device_name)

cleanup() {
    rm -rf "$LOG_DIR"
}
trap cleanup EXIT

mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
# Jacobi benchmark results

- Date: $(date '+%Y-%m-%dT%H:%M:%S%z')
- Host: $(uname -srmo)
- Device: \`$DEVICE_NAME\`
- Working tree: \`$ROOT_DIR\`

The reported \`time\` is the solver time printed by each implementation. Each
implementation was run once with its own default benchmark parameters.

| Implementation | Language | Device | Time (s) | Iterations | Final update error | Max error | L2 error |
|---|---|---|---:|---:|---:|---:|---:|
EOF

metric() {
    local pattern=$1
    local file=$2
    awk -v pattern="$pattern" 'index($0, pattern) == 1 {
        line = $0
        sub("^" pattern, "", line)
        sub("^[[:space:]]+", "", line)
        print line
        exit
    }' "$file"
}

run_benchmark() {
    local name=$1
    local language=$2
    local directory=$3
    shift 3

    local log_file="$LOG_DIR/$name.log"
    printf 'Running %-18s ... ' "$name"
    if (cd "$directory" && "$@") >"$log_file" 2>&1; then
        local time_value iterations update_error max_error l2_error
        time_value=$(metric 'time = ' "$log_file")
        iterations=$(metric 'Jacobi iterations = ' "$log_file")
        update_error=$(metric 'final update error = ' "$log_file")
        max_error=$(metric 'max error = ' "$log_file")
        l2_error=$(metric 'L2 error  = ' "$log_file")

        : "${time_value:=n/a}"
        : "${iterations:=n/a}"
        : "${update_error:=n/a}"
        : "${max_error:=n/a}"
        : "${l2_error:=n/a}"

        printf 'ok (%s)\n' "$time_value"
        printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
            "$name" "$language" "$DEVICE_NAME" "$time_value" "$iterations" \
            "$update_error" "$max_error" "$l2_error" >> "$RESULT_FILE"
    else
        printf 'failed\n'
        {
            printf '\n## %s (failed)\n\n' "$name"
            printf 'Command: `%s`\n\n' "$*"
            printf '```text\n'
            cat "$log_file"
            printf '```\n'
        } >> "$RESULT_FILE"
        printf 'Benchmark failed for %s; see %s\n' "$name" "$RESULT_FILE" >&2
        exit 1
    fi
}

run_benchmark "julia" "Julia" "$ROOT_DIR/julia" \
    julia --project=. poisson.jl

run_benchmark "python" "Python + Numba" "$ROOT_DIR/python" \
    uv run --project=. poisson.py

run_benchmark "cxx" "C++23" "$ROOT_DIR/cxx" \
    bash -c './build.sh && ./poisson'

run_benchmark "fortran" "Fortran 2008" "$ROOT_DIR/fortran" \
    bash -c './build.sh && ./poisson'

run_benchmark "rust" "Rust" "$ROOT_DIR/rust" \
    cargo run --release --manifest-path "$ROOT_DIR/rust/Cargo.toml"

printf '\nResults saved to %s\n' "$RESULT_FILE"
