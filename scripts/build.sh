#!/usr/bin/env bash

set -euo pipefail

container_version="starknet"

pushd "$(dirname -- "$0")/../core"
docker build . -t smartcontract/plugin:${container_version} -f ./core/plugin.Dockerfile
popd

