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


xoldunittest() {
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
# sudo apt-get install lcov
 x222unittest() {
    if [ -z "$1" ]; then
      echo "Usage: xunittest <package_name> [--coverage]"
      return 1
    fi

    local pkg="$1"
    local do_coverage=false

    # Check if coverage flag is provided
    if [ "$2" == "--coverage" ]; then
      do_coverage=true
      echo "Building with coverage enabled..."
    fi

    # Set build type and flags based on coverage
    local build_type="Release"
    local cmake_args="-DCMAKE_BUILD_TYPE=$build_type -DCATKIN_ENABLE_TESTING=ON"

    if [ "$do_coverage" = true ]; then
      build_type="Debug"
      # Add -fprofile-arcs -ftest-coverage for branch coverage
      cmake_args="-DCMAKE_BUILD_TYPE=$build_type -DCMAKE_CXX_FLAGS='-O0 -g -fprofile-arcs -ftest-coverage' -DCMAKE_C_FLAGS='-O0 -g -fprofile-arcs -ftest-coverage' 
  -DCMAKE_EXE_LINKER_FLAGS='-lgcov'"
    fi

    # Build and test
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args $cmake_args && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null

    # Generate coverage report if requested
    if [ "$do_coverage" = true ] && [ $? -eq 0 ]; then
      echo ""
      echo "=== Generating coverage report ==="
      local build_dir="build/$pkg"

      # Check if lcov is installed
      if ! command -v lcov &> /dev/null; then
        echo "ERROR: lcov not installed. Install with: sudo apt-get install lcov"
        return 1
      fi

      cd "$build_dir" || return 1

      # Capture coverage data WITH branch coverage
      echo "Capturing coverage data..."
      lcov --capture --directory . --output-file coverage.info \
        --rc lcov_branch_coverage=1 \
        --ignore-errors mismatch,unused \
        --quiet

      # Filter out system and test files
      echo "Filtering coverage data..."
      lcov --remove coverage.info \
        '/usr/*' '/opt/*' '*/test/*' '*/gtest/*' '*/_deps/*' '*/build/*' \
        --output-file coverage_filtered.info \
        --rc lcov_branch_coverage=1 \
        --ignore-errors unused,empty \
        --quiet

      # Generate HTML report
      echo "Generating HTML report..."
      genhtml coverage_filtered.info \
        --output-directory coverage_html \
        --rc lcov_branch_coverage=1 \
        --ignore-errors source \
        --quiet

      # Print summary
      echo ""
      echo "=== Coverage Summary ==="
      lcov --summary coverage_filtered.info --rc lcov_branch_coverage=1 2>/dev/null

      # Print report location
      local full_path="$(pwd)/coverage_html/index.html"
      echo ""
      echo "HTML Coverage Report: file://$full_path"
      echo ""

      cd - > /dev/null
    fi
}

#-fno-exceptions
x3333unittest() {
  if [ -z "$1" ]; then
    echo "Usage: xunittest <package_name> [--coverage]"
    return 1
  fi

  local pkg="$1"
  local do_coverage=false

  if [ "$2" == "--coverage" ]; then
    do_coverage=true
    echo "Building with coverage enabled..."
  fi

  local build_type="Release"

  if [ "$do_coverage" = true ]; then
    build_type="Debug"
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON \
        "-DCMAKE_CXX_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_C_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_EXE_LINKER_FLAGS=-lgcov" && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  else
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  fi

  if [ "$do_coverage" = true ] && [ $? -eq 0 ]; then
    echo ""
    echo "=== Generating coverage report ==="
    local build_dir="build/$pkg"

    if ! command -v lcov &> /dev/null; then
      echo "ERROR: lcov not installed. Install with: sudo apt-get install lcov"
      return 1
    fi

    cd "$build_dir" || return 1

    echo "Capturing coverage data..."
    lcov --capture --directory . --output-file coverage.info --rc branch_coverage=1 --rc geninfo_unexecuted_blocks=1 --ignore-errors mismatch,unused,gcov --quiet 2>/dev/null

    echo "Filtering coverage data..."
    lcov --remove coverage.info '/usr/*' '/opt/*' '*/test/*' '*/gtest/*' '*/_deps/*' '*/build/*' '*/install/*' --output-file coverage_filtered.info --rc branch_coverage=1 --ignore-errors unused,empty --quiet

    # Extract only source files from the current package (src and include directories)
    local workspace_root="$(cd ../.. && pwd)"
    local src_pattern="${workspace_root}/src/**/${pkg}/src/*"
    local include_pattern="${workspace_root}/src/**/${pkg}/include/*"
    lcov --extract coverage_filtered.info "${src_pattern}" "${include_pattern}" --output-file coverage_pkg_only.info --rc branch_coverage=1 --ignore-errors unused,empty 2>/dev/null

    # Use package-only coverage if extraction succeeded, otherwise use filtered
    local coverage_file="coverage_filtered.info"
    if [ -f coverage_pkg_only.info ] && [ -s coverage_pkg_only.info ]; then
      coverage_file="coverage_pkg_only.info"
      echo "Using package-only coverage data"
    fi

    echo "Generating HTML report..."
    genhtml "${coverage_file}" --output-directory coverage_html --rc branch_coverage=1 --ignore-errors source --quiet

    echo ""
    echo "=== Coverage Summary (Package Source Only) ==="
    lcov --summary "${coverage_file}" --rc branch_coverage=1 2>/dev/null

    local full_path="$(pwd)/coverage_html/index.html"
    echo ""
    echo "HTML Coverage Report: $full_path"
    echo ""

    cd - > /dev/null
  fi
}        

x444unittest() {
  if [ -z "$1" ]; then
    echo "Usage: xunittest <package_name> [--coverage]"
    return 1
  fi

  local pkg="$1"
  local do_coverage=false

  if [ "$2" == "--coverage" ]; then
    do_coverage=true
    echo "Building with coverage enabled..."
  fi

  local build_type="Release"

  if [ "$do_coverage" = true ]; then
    build_type="Debug"
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON \
        "-DCMAKE_CXX_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_C_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_EXE_LINKER_FLAGS=-lgcov" && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  else
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  fi

  if [ "$do_coverage" = true ] && [ $? -eq 0 ]; then
    echo ""
    echo "=== Generating coverage report ==="
    local build_dir="build/$pkg"

    if ! command -v lcov &> /dev/null; then
      echo "ERROR: lcov not installed. Install with: sudo apt-get install lcov"
      return 1
    fi

    cd "$build_dir" || return 1

    echo "Capturing coverage data..."
    lcov --capture --directory . --output-file coverage.info --rc branch_coverage=1 --rc
geninfo_unexecuted_blocks=1 --ignore-errors mismatch,unused,gcov --quiet 2>/dev/null

    echo "Filtering coverage data..."
    lcov --remove coverage.info '/usr/*' '/opt/*' '*/test/*' '*/gtest/*' '*/_deps/*' '*/build/*' '*/install/*' -
-output-file coverage_filtered.info --rc branch_coverage=1 --ignore-errors unused,empty --quiet

    # Extract only source files from the current package
    local workspace_root="$(cd ../.. && pwd)"
    local src_pattern="*/${pkg}/*"
    lcov --extract coverage_filtered.info "${src_pattern}" --output-file coverage_pkg_only.info --rc
branch_coverage=1 --ignore-errors unused,empty 2>/dev/null

    # Use package-only coverage if extraction succeeded, otherwise use filtered
    local coverage_file="coverage_filtered.info"
    if [ -f coverage_pkg_only.info ] && [ -s coverage_pkg_only.info ]; then
      coverage_file="coverage_pkg_only.info"
      echo "Using package-only coverage data"
    fi

    echo "Generating HTML report..."
    genhtml "${coverage_file}" --output-directory coverage_html --rc branch_coverage=1 --ignore-errors source -
-quiet

    echo ""
    echo "=== Coverage Summary (Package Source Only) ==="
    lcov --summary "${coverage_file}" --rc branch_coverage=1 2>/dev/null

    local full_path="$(pwd)/coverage_html/index.html"
    echo ""
    echo "HTML Coverage Report: $full_path"
    echo ""

    cd - > /dev/null
  fi
}

xunittest() {
  if [ -z "$1" ]; then
    echo "Usage: xunittest <package_name> [--coverage]"
    return 1
  fi

  local pkg="$1"
  local do_coverage=false

  if [ "$2" == "--coverage" ]; then
    do_coverage=true
    echo "Building with coverage enabled..."
  fi

  local build_type="Release"

  if [ "$do_coverage" = true ]; then
    build_type="Debug"
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON \
        "-DCMAKE_CXX_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_C_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
        "-DCMAKE_EXE_LINKER_FLAGS=-lgcov" && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  else
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=$build_type \
        -DCATKIN_ENABLE_TESTING=ON && \
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
  fi

  if [ "$do_coverage" = true ] && [ $? -eq 0 ]; then
    echo ""
    echo "=== Generating coverage report ==="
    local build_dir="build/$pkg"

    if ! command -v lcov &> /dev/null; then
      echo "ERROR: lcov not installed. Install with: sudo apt-get install lcov"
      return 1
    fi

    cd "$build_dir" || return 1

    echo "Capturing coverage data..."
    lcov --capture --directory . --output-file coverage.info --rc branch_coverage=1 --rc
geninfo_unexecuted_blocks=1 --ignore-errors mismatch,unused,gcov --quiet 2>/dev/null

    echo "Filtering coverage data..."
    lcov --remove coverage.info '/usr/*' '/opt/*' '*/test/*' '*/gtest/*' '*/_deps/*' '*/build/*' '*/install/*' -
-output-file coverage_filtered.info --rc branch_coverage=1 --ignore-errors unused,empty --quiet

    # Extract only source files from the current package (src and include directories)
    local workspace_root="$(cd ../.. && pwd)"
    local src_pattern="${workspace_root}/src/**/${pkg}/src/*"
    local include_pattern="${workspace_root}/src/**/${pkg}/include/*"
    lcov --extract coverage_filtered.info "${src_pattern}" "${include_pattern}" --output-file coverage_pkg_only.
info --rc branch_coverage=1 --ignore-errors unused,empty 2>/dev/null

    # Use package-only coverage if extraction succeeded, otherwise use filtered
    local coverage_file="coverage_filtered.info"
    if [ -f coverage_pkg_only.info ] && [ -s coverage_pkg_only.info ]; then
      coverage_file="coverage_pkg_only.info"
      echo "Using package-only coverage data"
    fi

    echo "Generating HTML report..."
    genhtml "${coverage_file}" --output-directory coverage_html --rc branch_coverage=1 --ignore-errors source -
-quiet

    echo ""
    echo "=== Coverage Summary (Package Source Only) ==="
    lcov --summary "${coverage_file}" --rc branch_coverage=1 2>/dev/null

    local full_path="$(pwd)/coverage_html/index.html"
    echo ""
    echo "HTML Coverage Report: $full_path"
    echo ""

    cd - > /dev/null
  fi
}

generate_coverage() {
    if [ $# -lt 1 ]; then
        echo "Usage: generate_coverage <package_name> [output_dir]"
        echo "Example: generate_coverage ugv_themis_dead_reckoning_ros"
        return 1
    fi

    local PACKAGE_NAME=$1
    local OUTPUT_DIR=${2:-"${PACKAGE_NAME}_coverage"}

    echo "Generating coverage for package: $PACKAGE_NAME"

    # Capture coverage data with branch coverage enabled
    lcov --capture --directory "build/$PACKAGE_NAME" --output-file coverage.info \
         --ignore-errors mismatch,negative,empty \
         --rc branch_coverage=1

    # Extract coverage for the specific package source files
    lcov --extract coverage.info "*/src/*/$PACKAGE_NAME/src/*" \
         --output-file "${PACKAGE_NAME}_coverage.info" \
         --rc branch_coverage=1

    # Generate HTML report with branch coverage enabled
    genhtml "${PACKAGE_NAME}_coverage.info" --output-directory "$OUTPUT_DIR" \
            --rc branch_coverage=1

    echo "Coverage report generated at: file:$(pwd)/$OUTPUT_DIR/index.html"
    echo "Coverage summary:"
    lcov --summary "${PACKAGE_NAME}_coverage.info" --rc branch_coverage=1
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

  # npm i -g opencode-ai

  echo "✅ Done! nvm and Node.js LTS are installed."
}

alias xcoverage='generate_coverage() {
    if [ $# -lt 1 ]; then
        echo "Usage: xcoverage <package_name> [output_dir]"
        echo "Example: xcoverage ros_utils"
        return 1
    fi
    local pkg="$1"
    local output_dir="${2:-${pkg}_coverage}"
    
    echo "🔧 Building $pkg with coverage flags..."
    colcon build --base-paths src --symlink-install --packages-select "$pkg" \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Debug \
            -DCATKIN_ENABLE_TESTING=ON \
            "-DCMAKE_CXX_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
            "-DCMAKE_C_FLAGS=-O0 -g -fprofile-arcs -ftest-coverage" \
            "-DCMAKE_EXE_LINKER_FLAGS=-lgcov" && \
    
    echo "🧪 Running tests for $pkg..."
    colcon test --base-paths src --packages-select "$pkg" && \
    script -q -c "colcon test-result --verbose --all" /dev/null
    if [ $? -eq 0 ]; then
        echo "📊 Generating coverage report..."
        local build_dir="build/$pkg"
        if ! command -v lcov &> /dev/null; then
            echo "❌ ERROR: lcov not installed. Install with: sudo apt-get install lcov"
            return 1
        fi
        cd "$build_dir" || return 1
        # Capture coverage data
        lcov --capture --directory . --output-file coverage.info \
            --rc branch_coverage=1 \
            --ignore-errors mismatch,unused,gcov \
            --quiet
        # Filter out system and test files
        lcov --remove coverage.info \
            "/usr/*" "/opt/*" "*/test/*" "*/gtest/*" "*/_deps/*" "*/build/*" "*/install/*" \
            --output-file coverage_filtered.info \
            --rc branch_coverage=1 \
            --ignore-errors unused,empty \
            --quiet
        # Extract only source files from the current package
        local workspace_root="$(cd ../.. && pwd)"
        local src_pattern="${workspace_root}/src/**/${pkg}/*"
        lcov --extract coverage_filtered.info "$src_pattern" \
            --output-file coverage_pkg_only.info \
            --rc branch_coverage=1 \
            --ignore-errors unused,empty \
            --quiet
        # Use package-only coverage if available
        local coverage_file="coverage_filtered.info"
        if [ -f coverage_pkg_only.info ] && [ -s coverage_pkg_only.info ]; then
            coverage_file="coverage_pkg_only.info"
            echo "✅ Using package-only coverage data"
        fi
        # Generate HTML report
        genhtml "$coverage_file" \
            --output-directory "$output_dir" \
            --rc branch_coverage=1 \
            --ignore-errors source \
            --quiet
        echo ""
        echo "📈 Coverage Summary:"
        lcov --summary "$coverage_file" --rc branch_coverage=1 2>/dev/null
        local full_path="$(pwd)/$output_dir/index.html"
        echo ""
        echo "🌐 HTML Coverage Report: file://$full_path"
        echo ""
        cd - > /dev/null
    else
        echo "❌ Tests failed for $pkg - coverage generation aborted"
        return 1
    fi
}; generate_coverage'