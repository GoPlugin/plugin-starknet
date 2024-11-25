#!/usr/bin/env bash

echo "Cleaning up devnet container.."

echo "Checking for existing 'plugin-starknet.starknet-devnet' docker container..."
dpid=`docker ps -a | grep plugin-starknet.starknet-devnet | awk '{print $1}'`;
if [ -z "$dpid" ]
then
    echo "No docker devnet container running.";
else
    docker kill $dpid;
    docker rm $dpid;
fi

echo "Cleanup finished."
