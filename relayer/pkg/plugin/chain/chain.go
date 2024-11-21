package starknet

import (
	"github.com/goplugin/plugin-relay/pkg/types"

	"github.com/goplugin/plugin-starknet/relayer/pkg/plugin/config"
	"github.com/goplugin/plugin-starknet/relayer/pkg/plugin/txm"
	"github.com/goplugin/plugin-starknet/relayer/pkg/starknet"

	// unused module to keep in go.mod and prevent ambiguous import
	_ "github.com/btcsuite/btcd/chaincfg/chainhash"
)

type ChainSet = types.ChainSet[string, Chain]

type Chain interface {
	types.ChainService

	Config() config.Config

	TxManager() txm.TxManager
	Reader() (starknet.Reader, error)
}
