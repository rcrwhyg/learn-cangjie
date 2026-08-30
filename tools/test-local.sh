#!/usr/bin/env bash

# Test canonical examples under examples/.
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

python3 .github/scripts/sync_examples.py

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

passed=0
skipped=0

test_cangjie() {
    command -v cjc >/dev/null || {
        printf '[ERROR] cjc is required\n' >&2
        return 1
    }

    local files=(examples/cangjie/*.cj)
    if [[ ! -e "${files[0]}" ]]; then
        printf '[SKIP] no Cangjie examples\n'
        skipped=$((skipped + 1))
        return 0
    fi

    local file output
    for file in "${files[@]}"; do
        output="$TMP_DIR/$(basename "${file%.cj}")"
        printf '[TEST] %s\n' "$file"
        if [[ "$(uname -s)" == "Darwin" ]]; then
            # The current macOS SDK cannot link the 1.0.5 native runtime.
            cjc "$file" --output-type staticlib -o "$output"
        else
            cjc "$file" --set-runtime-rpath -o "$output"
            if grep -q '^main()' "$file"; then
                "$output"
            fi
        fi
        passed=$((passed + 1))
    done
}

# Support cjpm multi-package projects (e.g. macro packages) under
# examples/cangjie/<name>/cjpm.toml. On macOS we can only run `cjpm check`
# because the SDK cannot link the 1.0.5 runtime (same reason single-file
# examples fall back to staticlib). On Linux we do full build + run.
test_cangjie_projects() {
    local found=0
    local dir
    for dir in examples/cangjie/*/; do
        [[ -f "$dir/cjpm.toml" ]] || continue
        found=1
        printf '[PROJECT] %s\n' "$dir"
        if [[ "$(uname -s)" == "Darwin" ]]; then
            (cd "$dir" && cjpm check)
        else
            (cd "$dir" && cjpm build)
            if grep -q 'output-type = "executable"' "$dir/cjpm.toml"; then
                (cd "$dir" && cjpm run)
            fi
        fi
        passed=$((passed + 1))
    done
    if [[ $found -eq 0 ]]; then
        printf '[SKIP] no Cangjie cjpm projects\n'
        skipped=$((skipped + 1))
    fi
}

test_language() {
    local language="$1"
    local extension="$2"
    local files=("examples/$language"/*."$extension")
    if [[ ! -e "${files[0]}" ]]; then
        printf '[SKIP] no %s examples\n' "$language"
        skipped=$((skipped + 1))
        return 0
    fi

    local file output
    for file in "${files[@]}"; do
        output="$TMP_DIR/$(basename "${file%.$extension}")"
        printf '[TEST] %s\n' "$file"
        case "$language" in
            java)
                javac "$file" -d "$TMP_DIR"
                ;;
            go)
                go run "$file"
                ;;
            kotlin)
                kotlinc "$file" -include-runtime -d "$output.jar"
                java -jar "$output.jar"
                ;;
            rust)
                rustc "$file" -o "$output"
                "$output"
                ;;
            cpp)
                g++ -std=c++17 "$file" -o "$output"
                "$output"
                ;;
            swift)
                swiftc "$file" -o "$output"
                "$output"
                ;;
            zig)
                zig run "$file"
                ;;
            python)
                python3 "$file"
                ;;
        esac
        passed=$((passed + 1))
    done
}

test_cangjie
test_cangjie_projects
test_language java java
test_language go go
test_language kotlin kt
test_language swift swift
test_language rust rs
test_language cpp cpp
test_language zig zig
test_language python py

printf '\nPassed: %d, skipped languages: %d\n' "$passed" "$skipped"
