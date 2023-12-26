#!/bin/env bash

ANDROID_HOME=/usr/lib/android-sdk

FENIX_VERSION=121.0
FENIX_SOURCE_TARBALL=fenix-v${FENIX_VERSION}.tar.gz
FENIX_SOURCE_URL=https://github.com/mozilla-mobile/firefox-android/archive/refs/tags/${FENIX_SOURCE_TARBALL}
FENIX_SOURCE_DIR=firefox-android-fenix-v${FENIX_VERSION}
POLARBEAR_ARCH="arm64"
PATCHES=`realpath ${PWD}`/patches
BRANDING=`realpath ${PWD}`/branding/res
TMP=`realpath build`

mkdir -p ${TMP}
pushd ${TMP}
wget -nc "${FENIX_SOURCE_URL}"
if [[ ! -d "${FENIX_SOURCE_DIR}" ]]; then
    tar --keep-newer-files -xf "${FENIX_SOURCE_TARBALL}"
else
    echo "${FENIX_SOURCE_DIR} is already there, not unpacking"
fi

pushd "${FENIX_SOURCE_DIR}"

# Remove unnecessary projects
rm -fR focus-android

# Patch the use of proprietary and tracking libraries
# patch -p1 --no-backup-if-mismatch --quiet < "${PATCHES}/01-fenix-liberate.patch"

#
# Android Components
#
# pushd "android-components"
# sed -i \
#     -e '/com.google.firebase/d' plugins/dependencies/src/main/java/DependenciesPlugin.kt || \
#     sed -i \
#         -e '/com.google.firebase/d' buildSrc/src/main/java/Dependencies.kt && \
#     rm -R components/lib/push-firebase
# popd

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

# # Remove proprietary and tracking libraries
# sed -i \
#     -e '/Deps.mozilla_lib_push_firebase/d' \
#     -e '/Deps.adjust/d; /Deps.installreferrer/d; /Deps.google_ads_id/d' \
#     -e '/Deps.google_play_store/d' \
#     -e '/project\('\:lib-push-firebase'\)/d' \
#     app/build.gradle

# Disable crash reporting
sed -i -e '/CRASH_REPORTING/s/true/false/' app/build.gradle

# Disable MetricController
sed -i -e '/TELEMETRY/s/true/false/' app/build.gradle

# We need only stable GeckoView
sed -i \
    -e '/Deps.mozilla_browser_engine_gecko_nightly/d' \
    -e '/Deps.mozilla_browser_engine_gecko_beta/d' \
    app/build.gradle

# Let it be Polarbear
sed -i \
    -e 's/Firefox Daylight/PolarBear/; s/Firefox/PolarBear/g' \
    -e '/about_content/s/Mozilla/Arctic Cloud/' \
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
