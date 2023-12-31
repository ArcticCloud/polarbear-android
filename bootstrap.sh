#!/bin/env bash

source "$HOME/.cargo/env"
rustup target add x86_64-linux-android
rustup target add i686-linux-android
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add thumbv7neon-linux-androideabi
cargo install cbindgen
