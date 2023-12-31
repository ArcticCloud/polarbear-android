source "$(dirname "$0")"/versions.sh

WASI_SDK_SOURCE_GIT_TAG=wasi-sdk-20
WASI_SDK_SOURCE_GIT_URL=https://github.com/WebAssembly/wasi-sdk.git
WASI_SDK_SOURCE_DIR=wasi-sdk

GECKO_SOURCE_HG_URL="https://hg.mozilla.org/mozilla-unified"
GECKO_SOURCE_HG_TAG="FIREFOX_${GECKO_VERSION//./_}_RELEASE"
GECKO_SOURCE_DIR="mozilla-unified"

FENIX_SOURCE_GIT_TAG=fenix-v${FENIX_VERSION}
FENIX_SOURCE_GIT_URL=https://github.com/mozilla-mobile/firefox-android.git
FENIX_SOURCE_DIR=firefox-android

ANDROID_NDK=${HOME}/.local/AndroidSdk/ndk/${ANDROID_NDK_VERSION}
