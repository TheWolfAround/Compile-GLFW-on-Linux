#!/bin/bash

# List of packages to check
packages="build-essential git ninja-build xorg-dev libwayland-dev libxkbcommon-dev wayland-protocols extra-cmake-modules"

update_package_index=0
# Loop through each package and check if it is installed
for pkg in $packages; do
    if dpkg -s "$pkg" 1> /dev/null; then
        echo "$pkg is already installed"
    else
        if [ $update_package_index -eq 0 ]; then
            sudo apt update
            update_package_index=1 #the script will update the package index once
        fi
        echo "$pkg is not installed"
        sudo apt install $pkg -y
    fi
done

if [ ! -d "glfw" ]; then
    git clone --depth 1 https://github.com/glfw/glfw.git
else
    echo "glfw folder already exists."
fi

echo
read -p "Choose CMake Generator (1 for Ninja, 2 for Make): " generator_choice
if [ "$generator_choice" -eq 1 ]; then
    CMAKE_GENERATOR="Ninja"
elif [ "$generator_choice" -eq 2 ]; then
    CMAKE_GENERATOR="Unix Makefiles"
else
    echo "Invalid CMake Generator choice. Please enter 1 or 2."
    exit 1
fi
echo
echo "Selected CMake Generator: $CMAKE_GENERATOR"
echo

echo
read -p "Choose build type (1 for Release, 2 for Debug): " build_choice
if [ "$build_choice" -eq 1 ]; then
    BUILD_TYPE="Release"
    COMPILE_FLAGS="-O2 -march=native"
elif [ "$build_choice" -eq 2 ]; then
    BUILD_TYPE="Debug"
    COMPILE_FLAGS="-O0 -g -ggdb"
else
    echo "Invalid build type choice. Please enter 1 or 2."
    exit 1
fi
echo
echo "Selected build type: $BUILD_TYPE"
echo

echo
read -p "Choose link type (1 for Static, 2 for Shared): " build_choice
if [ "$build_choice" -eq 1 ]; then
    LINK_TYPE="STATIC"
elif [ "$build_choice" -eq 2 ]; then
    LINK_TYPE="SHARED"
else
    echo "Invalid link type choice. Please enter 1 or 2."
    exit 1
fi
echo
echo "Selected link type: $LINK_TYPE"
echo

BUILD_DIR="__build_dir__glfw__/$BUILD_TYPE/$LINK_TYPE"
BUILD_OUT_DIR="__build_out__glfw__/$BUILD_TYPE/$LINK_TYPE"

cmake -G "$CMAKE_GENERATOR" \
    -D CMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -D CMAKE_C_FLAGS="$COMPILE_FLAGS" \
    -D CMAKE_INSTALL_PREFIX="$BUILD_OUT_DIR" \
    -D GLFW_LIBRARY_TYPE="$LINK_TYPE" \
    -D GLFW_BUILD_WAYLAND=ON \
    -D GLFW_BUILD_X11=ON \
    -D BUILD_SHARED_LIBS=OFF \
    -D GLFW_BUILD_EXAMPLES=OFF \
    -D GLFW_BUILD_TESTS=OFF \
    -D GLFW_BUILD_DOCS=OFF \
    -S ./glfw \
    -B "$BUILD_DIR"

NUM_THREADS=$(($(nproc) - 2))

if [ "$NUM_THREADS" -le 0 ]; then
    NUM_THREADS=1
fi

cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target install -j"$NUM_THREADS"
