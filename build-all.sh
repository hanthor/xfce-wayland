#!/bin/bash
# Batch build all XFCE Wayland components
# Usage: ./build-all.sh [--clean] [--xfwl4]
set -euo pipefail

REPO_ROOT="/var/home/james/dev/xfce-wayland"
INSTALL_PREFIX="$REPO_ROOT/install"
export PKG_CONFIG_PATH="$INSTALL_PREFIX/lib64/pkgconfig:$INSTALL_PREFIX/share/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$INSTALL_PREFIX/lib64:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$INSTALL_PREFIX/share:/usr/share"
export PATH="$INSTALL_PREFIX/bin:$PATH"

CLEAN=false
BUILD_XFWL4=false

for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=true ;;
        --xfwl4) BUILD_XFWL4=true ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

cd "$REPO_ROOT"

# Create catfish Python native file (needs system Python with dbus/gi/pexpect)
cat > /tmp/catfish-python.ini << 'PYEOF'
[binaries]
python = '/usr/bin/python3.12'

[python]
python = '/usr/bin/python3.12'
PYEOF

# Component build definitions: dir wayland_flag x11_flag
declare -a COMPONENTS=(
    "tumbler:false:false"
    "xfce4-appfinder:false:false"
    "xfce4-terminal:true:false"
    "xfce4-notifyd:true:false"
    "xfce4-power-manager:true:false"
    "thunar:false:true"
    "thunar-archive-plugin:false:false"
    "thunar-volman:false:false"
    "xfce4-places-plugin:false:false"
    "xfce4-genmon-plugin:false:false"
    "xfce4-taskmanager:false:true"
    "xfce4-clipman-plugin:true:false"
    "xfce4-verve-plugin:false:false"
    "xfce4-mount-plugin:false:false"
    "xfce4-pulseaudio-plugin:false:false"
    "xfce4-cpugraph-plugin:false:false"
    "xfce4-netload-plugin:false:false"
    "xfce4-diskperf-plugin:false:false"
    "xfce4-sensors-plugin:false:false"
    "xfce4-weather-plugin:false:false"
    "xfce4-screenshooter:true:false"
    "xfce4-screensaver:false:false"       # X11 only (libwlembed unavailable)
    "catfish:false:false"                  # Python/GTK3 (needs system Python)
    "xfce4-dict:false:false"               # GTK3 + panel plugin
    "xfce4-mpc-plugin:false:false"         # GTK3 panel plugin
    "mousepad:false:false"                 # GTK3 text editor
    "ristretto:false:false"                # GTK3 image viewer
)

build_component() {
    local dir="$1"
    local wayland="$2"
    local x11="$3"
    local path="$REPO_ROOT/$dir"

    if [[ ! -d "$path" ]]; then
        echo "[SKIP] $dir (not found)"
        return
    fi

    local meson_opts="-Dprefix=$INSTALL_PREFIX"
    [[ "$wayland" == "true" ]] && meson_opts="$meson_opts -Dwayland=enabled"
    [[ "$x11" == "true" ]] && meson_opts="$meson_opts -Dx11=disabled"

    # Special cases
    local native_file=""
    [[ "$dir" == "catfish" ]] && native_file="--native-file=/tmp/catfish-python.ini"
    [[ "$dir" == "xfce4-screensaver" ]] && meson_opts="$meson_opts -Dwayland=disabled -Dx11=enabled"

    echo "=== Building $dir ==="
    cd "$path"

    if [[ "$CLEAN" == true ]]; then
        echo "[CLEAN] Removing builddir"
        rm -rf builddir
    fi

    if [[ ! -d builddir ]] || [[ ! -f builddir/build.ninja ]]; then
        echo "[SETUP] meson $meson_opts $native_file"
        meson setup builddir $meson_opts $native_file 2>&1 | tail -2
    fi

    ninja -C builddir 2>&1 | tail -2
    echo ""
}

# Build all components
for comp in "${COMPONENTS[@]}"; do
    IFS=':' read -r dir wayland x11 <<< "$comp"
    build_component "$dir" "$wayland" "$x11"
done

# Build xfwl4 separately (Rust/meson hybrid)
if [[ "$BUILD_XFWL4" == true ]]; then
    echo "=== Building xfwl4 (winit backend) ==="
    cd "$REPO_ROOT/xfwl4"
    if [[ "$CLEAN" == true ]]; then
        rm -rf builddir
    fi
    cargo build --release --no-default-features -F winit -F egl -F xwayland 2>&1 | tail -3
    cp target/release/xfwl4 "$INSTALL_PREFIX/bin/xfwl4"
    echo ""

    echo "=== Building xfwl4 (tty backend) ==="
    cargo build --release --no-default-features -F udev -F egl -F xwayland 2>&1 | tail -3
    cp target/release/xfwl4 "$INSTALL_PREFIX/bin/xfwl4-tty"
    echo ""
fi

echo "=== Build complete ==="
echo "Binaries: $(ls $INSTALL_PREFIX/bin/ | wc -l)"
echo "Plugins: $(ls $INSTALL_PREFIX/lib64/xfce4/panel/plugins/ | wc -l)"
