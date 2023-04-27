#!/bin/bash

set -e -x

CURRENT_DIR="$(pwd)"
SOURCE_DIR="$CURRENT_DIR"

install_prefix="llvm+mlir-release"

CMAKE_CONFIGS="-DLLVM_ENABLE_PROJECTS=mlir;clang -DLLVM_INSTALL_UTILS=ON"
CMAKE_CONFIGS="${CMAKE_CONFIGS} -DLLVM_TARGETS_TO_BUILD=X86;NVPTX;AMDGPU"
CMAKE_CONFIGS="${CMAKE_CONFIGS} -DCMAKE_BUILD_TYPE=Release"

BUILD_DIR="$(mktemp -d)"
echo "Using a temporary directory for the build: $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp -r "$SOURCE_DIR/scripts" "$BUILD_DIR/scripts"
echo "Creating llvm-project.tar.gz"

pushd "$SOURCE_DIR"

tar -czf "$BUILD_DIR/llvm-project.tar.gz" llvm-project

popd

DOCKER_TAG="build"

DOCKER_REPOSITORY="clang-docker"

DOCKER_FILE_PATH="scripts/docker_ubuntu-18.04/Dockerfile"

echo "Building $DOCKER_REPOSITORY:$DOCKER_TAG using $DOCKER_FILE_PATH"

docker build -t $DOCKER_REPOSITORY:$DOCKER_TAG --build-arg cmake_configs="${CMAKE_CONFIGS}" --build-arg num_jobs=4 --build-arg install_dir_name="${install_prefix}" -f "$BUILD_DIR/$DOCKER_FILE_PATH" "$BUILD_DIR"

DOCKER_ID="$(docker create $DOCKER_REPOSITORY:$DOCKER_TAG)"

docker cp "$DOCKER_ID:/tmp/${install_prefix}.tar.xz" "${CURRENT_DIR}/"

docker rm "$DOCKER_ID"

rm -rf "$BUILD_DIR"

echo "Completed!"


