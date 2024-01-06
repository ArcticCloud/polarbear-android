#!/bin/env bash

set -xe

BUILD_ONLY="${1}"

source "$(dirname "$0")"/lib.sh
source "$(dirname "$0")"/versions.sh
source "$(dirname "$0")"/deps.sh

mkdir -p "${POLAR_BUILD_DIR}"
pushd "${POLAR_BUILD_DIR}"

#
# Wasi-SDK
#

if [[ -z $BUILD_ONLY || $BUILD_ONLY == wasi-sdk ]]; then

pushd "${WASI_SDK_SOURCE_DIR}"

mkdir -p build/install/wasi
touch build/compiler-rt.BUILT # fool the build system
make \
    PREFIX=/wasi \
    CC=clang \
    CXX=clang++ \
    build/wasi-libc.BUILT \
    build/libcxx.BUILT

popd

fi

#
# GeckoView
#

if [[ -z $BUILD_ONLY || $BUILD_ONLY == geckoview ]]; then

pushd "${GECKO_SOURCE_DIR}"

export MOZ_CHROME_MULTILOCALE=$(< "${PATCHES}/locales")

mkdir -p obj.faat/fetches

for _TARGET in x86 x86_64 arm64 arm; do

setup_arch "${_TARGET}"

export MOZCONFIG=mozconfig.${_TARGET}
./mach --verbose configure

_OBJ_DIR=obj.${_TARGET}

# this is no longer needed with latest Android NDK
sed -i \
    -e '/OS_LIBS += -landroid_support/d' \
    "${_OBJ_DIR}/toolkit/library/build/backend.mk"

./mach --verbose build
./mach --verbose gradle publishWithGeckoBinariesReleasePublicationToMavenLocal
./mach --verbose gradle exoplayer2:publishReleasePublicationToMavenLocal

BUILDID=$(grep -Poi "#define MOZ_BUILDID \\K(\\w+)" ${_OBJ_DIR}/buildid.h)
AAR_NAME=geckoview-omni-${ABI}-${GECKO_VERSION}.${BUILDID}.aar

cp -v ${_OBJ_DIR}/gradle/maven/org/mozilla/geckoview/geckoview-omni-${ABI}/${GECKO_VERSION}.${BUILDID}/${AAR_NAME} \
    obj.faat/fetches/

done

# build the fat AAR for all platforms

export MOZ_ANDROID_FAT_AAR_ARCHITECTURES="x86,x86_64,arm64-v8a,armeabi-v7a"

for _TARGET in x86 x86_64 arm64 arm; do

setup_arch "${_TARGET}"

_OBJ_DIR=obj.${_TARGET}
BUILDID=$(grep -Poi "#define MOZ_BUILDID \\K(\\w+)" ${_OBJ_DIR}/buildid.h)

AAR_NAME=geckoview-omni-${ABI}-${GECKO_VERSION}.${BUILDID}.aar
FAT_AAR_VAR=MOZ_ANDROID_FAT_AAR_${ABI//-/_}
FAT_AAR_VAR=${FAT_AAR_VAR^^}
export ${FAT_AAR_VAR}="${AAR_NAME}"

done

export MOZ_FETCHES_DIR=fetches
export MOZCONFIG=mozconfig.faat
./mach --verbose configure
./mach --verbose build android-fat-aar-artifact pre-export export
./mach --verbose gradle publishWithGeckoBinariesReleasePublicationToMavenLocal
./mach --verbose gradle exoplayer2:publishReleasePublicationToMavenLocal

popd

fi

#
# Fenix
#

if [[ -z $BUILD_ONLY || $BUILD_ONLY == fenix ]]; then

pushd "${FENIX_SOURCE_DIR}"

pushd "fenix"
gradle assembleRelease
popd

popd

fi
