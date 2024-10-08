#!/usr/bin/env bash

# Build package(s)

# Exit on any failure
set -e

help() {
    echo "Usage: build.sh [OPTIONS] <PACKAGE>

<PACKAGE>: Optional WASM package name. Builds all packages if not specified.

OPTIONS:
    -h, --help: Print help information
    -u, --update: Update client dependency
"
    exit 0
}

# Check for help option
if [ "$1" = "--help" ]; then
    help
fi

# Parse arguments
args=()
update=false

while [[ $# -gt 0 ]]; do
    case $1 in
    -u | --update)
        update=true
        shift
        ;;
    -*)
        echo "Unknown option '$1'"
        exit 1
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done

# Define all package names
all_packages=(
    "anchor-cli"
    "rust-analyzer"
    "seahorse-compile"
    "solana-cli"
    "spl-token-cli"
    "sugar-cli"
)

# VSCode specific packages
vscode_packages=("${all_packages[@]:2}")

# Get script directory (which is wasm/), and root directory (which is one level higher)
wasm_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
root_dir=$(dirname "$wasm_dir")

# Function to build a specified package
build() {
    local package="$1"
    echo "Building '$package'..."

    package_dir="$wasm_dir/$package"

    # Check whether the package directory exists
    if [ ! -d "$package_dir" ]; then
        echo "Error: no package named '$package' found in wasm/"
        echo "Valid packages: ${all_packages[@]}"
        exit 1
    fi

    pushd "$package_dir" > /dev/null

    # Directly set the toolchain based on the specified version
    echo "Installing Rust toolchain version 1.75.0"
    rustup toolchain install 1.75.0 --component rust-src

    # Ensure rustfmt is installed as per your toml config
    rustup component add rustfmt

    # Rust Analyzer requires `--target web`
    if [ "$package" = "rust-analyzer" ]; then
        wasm-pack build --target web
    else
        wasm-pack build

        # Handle a WASM bug from `solana_sdk::instruction::SystemInstruction`
        package_name=$(awk -F '"' '/^name/{print $2}' Cargo.toml | sed "s/-/_/g")

        # Comment out the following line
        line="wasm.__wbg_systeminstruction_free(ptr);"

        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s/$line/\/\/$line/" "pkg/${package_name}_bg.js"
        else
            sed -i "s/$line/\/\/$line/" "pkg/${package_name}_bg.js"
        fi
    fi

    popd > /dev/null
}

# Determine packages to build
if [ ${#args[@]} -ne 0 ]; then
    packages="${args[@]}"
else
    packages="${all_packages[@]}"
fi

# Build and update client packages
client_package_names=""

for package in $packages; do
    build "$package"
    client_package_names="${client_package_names}@solana-playground/$package "
done

# Exit early if `--update` is not specified
if [ "$update" != true ]; then
    exit 0
fi

# Update client packages
echo "Updating client packages: $client_package_names"
cd "$root_dir/client" && yarn install --frozen-lockfile && yarn upgrade $client_package_names

# Update VSCode packages
vscode_package_names=""

for package in "${vscode_packages[@]}"; do
    vscode_package_names="${vscode_package_names}@solana-playground/$package "
done

echo "Updating VSCode packages: $vscode_package_names"
cd "$root_dir/vscode" && yarn install --frozen-lockfile && yarn upgrade $vscode_package_names
