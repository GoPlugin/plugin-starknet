# STOM

## Useful links

- Starknet on-chain monitor [generated docs](https://pkg.go.dev/github.com/goplugin/plugin-starknet/monitoring/pkg/monitoring).
- On-chain monitoring (OM) framework architecture docs in [blueprints](https://github.com/goplugin/pluginv3.0-blueprints/blob/master/monitoring/README.md).
- OM framework [generated docs](https://pkg.go.dev/github.com/goplugin/plugin-common/pkg/monitoring).

## Local development

Note: Previously, this monitor also wrote to Kafka, but the dependency on Kafka has been removed in order to simplify deployment. The kafka topics were unused anyway.

- Start an http server that mimics weiwatchers locally. It needs to export a json configuration file for feeds:

```json
[
  {
    "name": "PLI / USD",
    "path": "link-usd",
    "symbol": "$",
    "heartbeat": 0,
    "contract_type": "numerical_median_feed",
    "status": "testing",
    "contract_address": "<CONTRACT_ADDRESS>",
    "multiply": "100000000",
    "proxy_address": "<PROXY_ADDRESS>"
  }
]
```

It also needs to export a json configuration for for node operators:

```json
[
  {
    "id": "noop",
    "nodeAddress": [<NODE_OPERATOR_ADDRESS>]
  }
]
```

One option is to create a folder `/tmp/configs` and add two files `feeds.json` and `nodes.json` with the configs from above, then:

```bash
python3 -m http.server 4000
```

- Start STOM locally. You will need and RPC endpoint and the address of the PLI token. Make sure you `cd ./monitoring`.

```bash
STARKNET_RPC_ENDPOINT="<RPC_ENDPOINT>" \
STARKNET_NETWORK_NAME="devnet" \
STARKNET_NETWORK_ID="1" \
STARKNET_CHAIN_ID="1" \
STARKNET_READ_TIMEOUT="5s" \
STARKNET_POLL_INTERVAL="10s" #test \
STARKNET_PLI_TOKEN_ADDRESS="<PLI_TOKEN_ADDRESS>" \
HTTP_ADDRESS="localhost:3000" \
FEEDS_URL="http://localhost:4000/feeds.json" \
NODES_URL="http://localhost:4000/nodes.json" \
go run ./cmd/monitoring/main.go
```

- Check the output for the Prometheus scraper

```bash
curl http://localhost:3000/metrics
```
