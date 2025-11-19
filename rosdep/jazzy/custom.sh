# alias xbuild="catkin build -DCMAKE_BUILD_TYPE=Release -c"
# alias xbuildeb="catkin build -DCMAKE_BUILD_TYPE=Debug -c"

xbuild() {
    local BUILD_TYPE="Release"
    local BASE_PATH="/home/developer/workspace/src"
    local EXTRA_ARGS=()
    local PKG=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --release-type)
            shift
            BUILD_TYPE="$1"
            ;;
        --*)
            EXTRA_ARGS+=("$1")
            ;;
        *)
            if [[ -z "$PKG" ]]; then
                PKG="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$PKG" ]]; then
        echo "[xbuild] Building all packages in $BASE_PATH with CMAKE_BUILD_TYPE=$BUILD_TYPE"
        colcon build --base-paths "$BASE_PATH" --symlink-install --cmake-args -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${EXTRA_ARGS[@]}" --parallel-workers 2
    else
        echo "[xbuild] Building package '$PKG' in $BASE_PATH with CMAKE_BUILD_TYPE=$BUILD_TYPE"
        colcon build --base-paths "$BASE_PATH" --symlink-install --packages-select "$PKG" --cmake-args -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${EXTRA_ARGS[@]}" --parallel-workers 2
    fi
}

xbuilddeb() {
    local BUILD_TYPE="Debug"
    local BASE_PATH="/home/developer/workspace/src"
    local EXTRA_ARGS=()
    local PKG=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --release-type)
            shift
            BUILD_TYPE="$1"
            ;;
        --*)
            EXTRA_ARGS+=("$1")
            ;;
        *)
            if [[ -z "$PKG" ]]; then
                PKG="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            ;;
        esac
        shift
    done

    if [[ -z "$PKG" ]]; then
        echo "[xbuild] Building all packages in $BASE_PATH with CMAKE_BUILD_TYPE=$BUILD_TYPE"
        colcon build --base-paths "$BASE_PATH" --symlink-install --cmake-args -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${EXTRA_ARGS[@]}"
    else
        echo "[xbuild] Building package '$PKG' in $BASE_PATH with CMAKE_BUILD_TYPE=$BUILD_TYPE"
        colcon build --base-paths "$BASE_PATH" --symlink-install --packages-select "$PKG" --cmake-args -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${EXTRA_ARGS[@]}"
    fi
}

xclean() {
    set -euo pipefail
    # assume workspace layout: <ws>/{src,build,install,log}
    local SRC_DIR="${SRC_DIR:-src}"

    if [ -z "${1:-}" ]; then
        echo "No package specified. Cleaning entire workspace..."
        rm -rf build/ install/ log/
    else
        local PKG="$1"
        echo "Cleaning package: ${PKG}"
        # Restrict discovery to the source tree only (avoids venv/…/site-packages)
        colcon build --base-paths "${SRC_DIR}" --packages-select "${PKG}" --cmake-target clean
        rm -rf "build/${PKG}" "install/${PKG}"
    fi
}


xunittest() {
  if [ -z "$1" ]; then
    echo "Usage: xunittest <package_name>"
    return 1
  fi

  local pkg="$1"

  colcon build --base-paths src --symlink-install --packages-select "$pkg" --cmake-args -DCMAKE_BUILD_TYPE=Release -DCATKIN_ENABLE_TESTING=ON && \
  colcon test --base-paths src --packages-select "$pkg" && \
#   colcon test-result --verbose --all
  script -q -c "colcon test-result --verbose --all" /dev/null

}

# alias xbuild="catkin build -DCMAKE_BUILD_TYPE=Release -c"
# alias xbuildeb="catkin build -DCMAKE_BUILD_TYPE=Debug -c"
# alias xsimu="roslaunch ugv_launch demo.launch type:=simulation "
#roslaunch ugv_launch demo.launch namespace:=sbuggy type:=real #namespace:= [fjcruiser,mbuggy,tbuggy,sbuggy,satv] type:=[real,simulation,rosbag]
# alias xdemo="roslaunch ugv_launch demo.launch type:=real "
#python robots/git_clone.py --namespace tbuggy --simulation
# alias xclone="python robots/git_clone.py --namespace "
# alias xutest="catkin run_tests "

alias xtfview="rosrun tf view_frames"
alias xrconsole="rqt_console"

alias xinstallgit="cd ~; wget https://release.axocdn.com/linux/gitkraken-amd64.tar.gz; tar zxf gitkraken-amd64.tar.gz;rm gitkraken-amd64.tar.gz;cd -;"
alias xgitkrak="cd ~/gitkraken && { ./gitkraken --no-sandbox &> /dev/null & cd -; }"

# alias xinstallgit="cd ~; wget https://release.axocdn.com/linux/gitkraken-amd64.deb; apt install -y ./gitkraken-amd64.deb;rm gitkraken-amd64.deb;cd -;"
# alias xgitkrak="gitkraken --no-sandbox"

#bash
xsimu() {
    roslaunch ugv_launch demo.launch type:=simulation sim_engine:=gazebo namespace:=$1
}

#roslaunch ugv_launch demo.launch namespace:=sbuggy type:=real #namespace:= [fjcruiser,mbuggy,tbuggy,sbuggy,satv] type:=[real,simulation,rosbag]
xdemo() {
    roslaunch ugv_launch demo.launch type:=real namespace:=$1
}

xclone() {
    python robots/git_clone.py --simulation --test --namespace $1
}

xplay() {
    /home/developer/workspace/robots/ugv_deploy/scripts/play_bags.sh $1 auto
}

xgitpermission()
{
    git config --global --add safe.directory '*'
}

# alias xclang="find . -iname \"*.h\" -o -iname \"*.*pp\" -o -iname \"*.proto\" | xargs clang-format -i -style=file"
alias xclang="find . -iname '*.h' -o -iname '*.*pp' -o -iname '*.proto' | xargs -d '\n' clang-format -i -style=file"

alias xros="source devel/setup.bash"

export DISABLE_ROS1_EOL_WARNINGS=1

# https://github.com/sharkdp/hyperfine
xhyper() {
    if ! command -v hyperfine &>/dev/null; then
        echo "hyperfine not found. Installing..."
        wget -q https://github.com/sharkdp/hyperfine/releases/download/v1.19.0/hyperfine_1.19.0_amd64.deb -O /tmp/hyperfine.deb
        sudo dpkg -i /tmp/hyperfine.deb
    fi
    hyperfine "$@"
}
#   hyperfine \
#     --runs 5 \
#     --warmup 2 \
#     --prepare 'sync' \
#     --export-markdown /tmp/rostest_benchmark.md \
#     --export-json /tmp/rostest_benchmark.json \
#     --show-output \
#     'rostest --text ugv_tests test_obstacle_stop.test namespace:=terberg rviz_gui:=true gazebo_gui:=false test_id:$(date +%Y%m%d_%H%M%S)'
# }

# alias xinstallgit="cd ~; wget https://release.axocdn.com/linux/gitkraken-amd64.tar.gz; tar zxf gitkraken-amd64.tar.gz;rm gitkraken-amd64.tar.gz;cd -;"
# alias xgitkrak="cd ~/gitkraken && { ./gitkraken --no-sandbox &> /dev/null & cd -; }"

# pgrep -fl fast_lio
# sudo /usr/lib/linux-tools/5.15.0-75-generic/perf record -F 199 -p 266862 -g -- sleep 30
# hotspot

xfixdrivers() {
    echo "🔄 Updating Mesa drivers..."
    apt update &&
        apt install -y software-properties-common &&
        add-apt-repository ppa:kisak/kisak-mesa -y &&
        apt update &&
        apt upgrade mesa-* -y &&
        echo "✅ Mesa update complete!"
}

 
xinstallnvm() {
  echo "=> Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
 
  echo "=> Reloading shell config..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
 
  echo "=> Installing latest LTS Node.js..."
  nvm install --lts
 
  echo "=> Verifying installation..."
  node --version
  npm --version
 
  npm i -g opencode-ai
 
  echo "✅ Done! nvm and Node.js LTS are installed."
}