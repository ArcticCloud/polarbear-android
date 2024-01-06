#!/bin/env bash

set -xe

source "$(dirname "$0")"/lib.sh
source "$(dirname "$0")"/versions.sh
source "$(dirname "$0")"/deps.sh

mkdir -p "${POLAR_BUILD_DIR}"
pushd "${POLAR_BUILD_DIR}"

#
# Wasi-SDK
#
fetch_git_vcs "$WASI_SDK_SOURCE_GIT_URL" "$WASI_SDK_SOURCE_GIT_TAG" "$WASI_SDK_SOURCE_DIR"

pushd "${WASI_SDK_SOURCE_DIR}"

popd

#
# GeckoView
#

fetch_hg_vcs "$GECKO_SOURCE_HG_URL" "$GECKO_SOURCE_HG_TAG" "$GECKO_SOURCE_DIR"

pushd "${GECKO_SOURCE_DIR}"

patch_if_needed "${PATCHES}/gecko-liberate.patch"

sed -i \
    -e '/com.google.android.gms/d' \
    mobile/android/geckoview/build.gradle

sed -i \
    -e 's/r23c/r26b/' \
    python/mozboot/mozboot/android.py

sed -i \
    -e 's/build_tools_version="33.0.1"/build_tools_version="34.0.0"/' \
    -e 's/target_sdk_version="33"/target_sdk_version="34"/' \
    build/moz.configure/android-sdk.configure

# Remove Mozilla repositories substitution and explicitly add the required ones
sed -i \
    -e '/maven {/,/}$/d; /gradle.mozconfig.substs/,/}$/{N;d;}' \
    -e '/repositories {/a\        mavenLocal()' \
    -e '/repositories {/a\        maven { url "https://plugins.gradle.org/m2/" }' \
    -e '/repositories {/a\        google()' \
    build.gradle

# Configure
sed -i -e '/check_android_tools("emulator"/d' build/moz.configure/android-sdk.configure
for _TARGET in x86 x86_64 arm64 arm; do

setup_arch "${_TARGET}"

cat << EOF > mozconfig.${_TARGET}
export MOZILLA_OFFICIAL=1
ac_add_options --disable-crashreporter
ac_add_options --disable-updater
ac_add_options --disable-debug
ac_add_options --disable-nodejs
ac_add_options --disable-profiling
ac_add_options --disable-rust-debug
ac_add_options --disable-tests
ac_add_options --disable-debug-symbols
ac_add_options --enable-compile-environment
ac_add_options --enable-application=mobile/android
ac_add_options --enable-hardening
ac_add_options --enable-optimize
ac_add_options --enable-mobile-optimize
ac_add_options --enable-release
# ac_add_options --enable-minify=properties # JS minification breaks addons
ac_add_options --enable-update-channel=release
ac_add_options --enable-rust-simd
ac_add_options --enable-strip
ac_add_options --enable-js-shell
ac_add_options --host=$(clang -dumpmachine)
ac_add_options --target=$TARGET
ac_add_options --with-android-min-sdk=$MINSDK
ac_add_options --with-android-ndk="$ANDROID_NDK"
ac_add_options --with-android-sdk="$ANDROID_SDK"
ac_add_options --with-java-bin-path="/usr/bin"
ac_add_options --with-gradle=$(command -v gradle)
ac_add_options --with-wasi-sysroot="${POLAR_BUILD_DIR}/${WASI_SDK_SOURCE_DIR}/build/install/wasi/share/wasi-sysroot"
ac_add_options HOST_CC="$(command -v clang)"
ac_add_options HOST_CXX="$(command -v clang++)"
ac_add_options CC="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$TRIPLET-clang"
ac_add_options CXX="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$TRIPLET-clang++"
ac_add_options STRIP="$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
ac_add_options WASM_CC="${POLAR_BUILD_DIR}/${WASI_SDK_SOURCE_DIR}/build/install/wasi/bin/clang"
ac_add_options WASM_CXX="${POLAR_BUILD_DIR}/${WASI_SDK_SOURCE_DIR}/build/install/wasi/bin/clang++"
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj.${_TARGET}
EOF

done

cat "${PATCHES}/preferences/userjs-arkenfox.js" >> mobile/android/app/geckoview-prefs.js
cat "${PATCHES}/preferences/userjs-brace.js" >> mobile/android/app/geckoview-prefs.js

popd

#
# Firefox Android
#

fetch_git_vcs "$FENIX_SOURCE_GIT_URL" "$FENIX_SOURCE_GIT_TAG" "$FENIX_SOURCE_DIR"

pushd "${FENIX_SOURCE_DIR}"

# Remove unnecessary projects
rm -fR focus-android
rm -f fenix/app/src/test/java/org/mozilla/fenix/components/ReviewPromptControllerTest.kt
rm -rf fenix/app/src/{beta,nightly,debug}

# Patch the use of proprietary and tracking libraries
patch_if_needed \
    "${PATCHES}/fenix-liberate.patch" \
    "${PATCHES}/strict-etp.patch" \
    "${PATCHES}/0001-Remove-Pocket-from-Fenix.patch"

#
# Android Components
#
pushd "android-components"
sed -i \
    -e '/com.google.firebase/d' plugins/dependencies/src/main/java/DependenciesPlugin.kt || \
    sed -i \
        -e '/com.google.firebase/d' buildSrc/src/main/java/Dependencies.kt && \
    rm -R components/lib/push-firebase

rsync -avr ${PATCHES}/components components

popd

#
# Fenix
#

pushd "fenix"
# Set up the app ID, version name and version code
sed -i \
    -e 's|applicationId "org.mozilla"|applicationId "xyz.stashed"|' \
    -e 's|applicationIdSuffix ".firefox"|applicationIdSuffix ".polarbear"|' \
    -e 's|"sharedUserId": "org.mozilla.firefox.sharedID"|"sharedUserId": "xyz.stashed.polarbear.sharedID"|' \
    app/build.gradle
sed -i \
    -e '/android:targetPackage/s/org.mozilla.firefox/xyz.stashed.polarbear/' \
    app/src/release/res/xml/shortcuts.xml

# Remove proprietary and tracking libraries
sed -i \
    -e '/Deps.mozilla_lib_push_firebase/d' \
    -e '/Deps.adjust/d; /Deps.installreferrer/d; /Deps.google_ads_id/d' \
    -e '/Deps.google_play_store/d' \
    app/build.gradle

# Disable crash reporting
sed -i -e '/CRASH_REPORTING/s/true/false/' app/build.gradle

# Disable MetricController
sed -i -e '/TELEMETRY/s/true/false/' app/build.gradle

# We need only stable GeckoView
sed -i \
    -e '/Deps.mozilla_browser_engine_gecko_nightly/d' \
    -e '/Deps.mozilla_browser_engine_gecko_beta/d' \
    app/build.gradle

# Let it be PolarBear
sed -i \
    -e 's/Firefox Daylight/PolarBear/; s/Firefox/PolarBear/g' \
    -e '/about_content/s/Mozilla/Arctic Works/' \
    app/src/*/res/values*/*strings.xml

# Replace proprietary artwork
rm app/src/release/res/drawable/ic_launcher_foreground.xml
rm app/src/release/res/mipmap-*/ic_launcher.webp
rm app/src/release/res/values/colors.xml
rm app/src/main/res/values-v24/styles.xml
sed -i -e '/android:roundIcon/d' app/src/main/AndroidManifest.xml
sed -i -e '/SplashScreen/,+5d' app/src/main/res/values-v27/styles.xml
find "${BRANDING}" -type f | while read -r src; do
    dst=app/src/release/res/${src#"${BRANDING}"}
    mkdir -p "$(dirname "$dst")"
    cp -v "$src" "$dst"
done

# Enable about:config
sed -i \
    -e 's/aboutConfigEnabled(.*)/aboutConfigEnabled(true)/' \
    app/src/*/java/org/mozilla/fenix/*/GeckoProvider.kt

# Expose "Custom Add-on collection" setting
sed -i \
    -e 's/Config.channel.isNightlyOrDebug && //' \
    app/src/main/java/org/mozilla/fenix/components/Components.kt
sed -i \
    -e 's/Config.channel.isNightlyOrDebug && //' \
    app/src/main/java/org/mozilla/fenix/settings/SettingsFragment.kt

# Disable periodic user notification to set as default browser
sed -i \
    -e 's/!defaultBrowserNotificationDisplayed && !isDefaultBrowserBlocking()/false/' \
    app/src/main/java/org/mozilla/fenix/utils/Settings.kt

# Always show the Quit button
sed -i \
    -e 's/if (settings.shouldDeleteBrowsingDataOnQuit) quitItem else null/quitItem/' \
    -e '/val settings = context.components.settings/d' \
    app/src/main/java/org/mozilla/fenix/home/HomeMenu.kt

# Expose "Pull to refresh" setting
sed -i \
    -e '/pullToRefreshEnabled = /s/Config.channel.isNightlyOrDebug/true/' \
    app/src/main/java/org/mozilla/fenix/FeatureFlags.kt

# Disable "Pull to refresh" by default
sed -i \
    -e '/pref_key_website_pull_to_refresh/{n; s/default = true/default = false/}' \
    app/src/main/java/org/mozilla/fenix/utils/Settings.kt

popd

popd