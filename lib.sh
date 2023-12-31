function error() {
  printf "ERROR: $*\\n"
  exit 1
}

function info() {
  printf "INFO: $*\\n"
}

function localize_maven {
    # Replace custom Maven repositories with mavenLocal()
    find ./* -name '*.gradle' -type f -print0 | xargs -0 \
        sed -n -i \
            -e '/maven {/{:loop;N;/}$/!b loop;/plugins.gradle.org/!s/maven .*/mavenLocal()/};p'
    # Make gradlew scripts call our Gradle wrapper
    find ./* -name gradlew -type f | while read -r gradlew; do
        echo 'gradle "$@"' > "$gradlew"
        chmod 755 "$gradlew"
    done
}

function fetch_and_unpack() {
  local _URL="$1"
  local _NAME="$2"
  wget --continue --no-clobber "$_URL" -O "$_NAME" || info "Continuing..."
  if [[ $_NAME == *.zip ]]; then
    unzip $_NAME -d .
  elif [[ $_NAME == *.tar.gz ]]; then
    tar --overwrite -xf $_NAME
  else
    7z x "$_NAME"
  fi
}

function fetch_git_vcs() {
  local _GITURL="$1"
  local _GITTAG="$2"
  local _DIR="$3"
  if [[ ! -d "$_DIR" ]]; then
    git clone --recursive \
      --branch "$_GITTAG" \
      "$_GITURL" "$_DIR"
  else
    pushd "$_DIR"
    git checkout -f "$_GITTAG"
    popd
  fi
}

function fetch_hg_vcs() {
  local _HGURL="$1"
  local _HGTAG="$2"
  local _DIR="$3"
  if [[ ! -d "$_DIR" ]]; then
    hg clone --rev="$_HGTAG" "$_HGURL" "$_DIR"
  else
    pushd "$_DIR"
    # hg update --clean -r "$_HGTAG"
    popd
  fi
}

function reset_dir() {
  local _DIR="$1"
  if [[ -d "${_DIR}" ]]; then
    read -p "This will delete ${_DIR}. Are you sure? (y/n): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "Removing ${_DIR}..."
      rm -rvf "${_DIR}"
    fi
  fi
}

function patch_if_needed() {
  if [[ ! -f .polar_bear_patched ]]; then
    for _PATCH in $*; do
      info "Patching with ${_PATCH}"
      patch -p1 -N --no-backup-if-mismatch --quiet < "${_PATCH}"
    done
    touch .polar_bear_patched
  else
    echo "Already patched...."
  fi
}

function setup_arch() {
  # Set up target parameters
  local _ARCH=$1
  case "$_ARCH" in
      arm)
          ABI=armeabi-v7a
          TARGET=armv7a-linux-androideabi
          RUST_TARGET=armv7
          TRIPLET="${TARGET}$MINSDK"
          ;;
      x86)
          ABI=x86
          TARGET=x86-linux-android
          RUST_TARGET=i686
          TRIPLET="${TARGET}${MINSDK}"
          ;;
      x86_64)
          ABI=x86_64
          TARGET=x86_64-linux-android
          RUST_TARGET=x86_64
          TRIPLET="${TARGET}${MINSDK}"
          ;;
      arm64)
          ABI=arm64-v8a
          TARGET=aarch64-linux-android
          RUST_TARGET=arm64
          TRIPLET="${TARGET}$MINSDK"
          ;;
      *)
          error "Unknown target code in ${_ARCH}." >&2
          exit 1
      ;;
  esac
}

if [[ -z $ANDROID_HOME ]]; then
  error "ANDROID_HOME must be set !!!"
fi

POLAR_BUILD_DIR=`realpath build`
PATCHES=`realpath ${PWD}`/patches
BRANDING=`realpath ${PWD}`/branding/res
ANDROID_SDK=$ANDROID_HOME
