#!/usr/bin/env bash

set -euo pipefail

# cpu_struct=`arch`;
# echo $cpu_struct;
cpu_struct="linux";

# Clean up first
bash "$(dirname -- "$0";)/devnet.down.sh"

echo "Checking CPU structure..."
if [[ $cpu_struct == *"arm"* ]]
then
    echo "Starting arm devnet container..."
    container_version="a147b4cd72f9ce9d1fa665d871231370db0f51c7-arm"
else
    echo "Starting i386 devnet container..."
    container_version="a147b4cd72f9ce9d1fa665d871231370db0f51c7"
fi

echo "Starting starknet-devnet"

container_name="plugin-starknet.starknet-devnet"

# we need to replace the entrypoint because starknet-devnet's docker builds at 0.5.1 don't include cargo or gcc.
docker run \
  -p 127.0.0.1:5050:5050 \
  -p 127.0.0.1:8545:8545 \
  --rm \
  -d \
	--name "${container_name}" \
	--network-alias "${container_name}" \
	--network plugin \
  "shardlabs/starknet-devnet-rs:${container_version}" \
  --seed 0 \
  --gas-price 1 \
  --data-gas-price 1 \
  --account-class cairo1

# echo "Starting hardhat..."
# docker run --net container:plugin-starknet.starknet-devnet -d --name plugin-starknet.hardhat ethereumoptimism/hardhat-node:nightly

# starknet-devnet startup is slow and requires compiling cairo.
echo "Waiting for starknet-devnet to become ready.."
start_time=$(date +%s)
prev_output=""
while true
do
  output=$(docker logs plugin-starknet.starknet-devnet 2>&1)
  if [[ "${output}" != "${prev_output}" ]]; then
    echo -n "${output#$prev_output}"
    prev_output="${output}"
  fi

  if [[ $output == *"listening"* ]]; then
    echo ""
    echo "starknet-devnet is ready."
    exit 0
  fi

  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))

  if (( elapsed_time > 600 )); then
    echo "Error: Command did not become ready within 600 seconds"
    exit 1
  fi

  sleep 3
done
