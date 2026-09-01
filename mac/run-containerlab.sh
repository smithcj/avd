#!/usr/bin/env bash
set -euo pipefail

IMAGE="avd-containerlab-mac:0.79.0"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker command not found."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker Desktop is not running or is not accessible."
    exit 1
fi

if [[ ! -f "${REPO_ROOT}/lab1.clab.yml" ]]; then
    echo "ERROR: ${REPO_ROOT}/lab1.clab.yml was not found."
    exit 1
fi

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
    echo "Containerlab helper image '${IMAGE}' not found."
    echo "Building from ${SCRIPT_DIR}/Dockerfile..."
    docker build -t "${IMAGE}" "${SCRIPT_DIR}"
fi

echo "Repository: ${REPO_ROOT}"
echo "Image:      ${IMAGE}"
echo
echo "Inside the container:"
echo "  cd /workspace"
echo "  containerlab deploy -t lab1.clab.yml"
echo

exec docker run --rm -it \
    --privileged \
    --pid=host \
    --network=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /run/docker/netns:/run/docker/netns \
    -v /var/lib/docker:/var/lib/docker \
    -v "${REPO_ROOT}:/workspace" \
    -w /workspace \
    "${IMAGE}" \
    /bin/bash

