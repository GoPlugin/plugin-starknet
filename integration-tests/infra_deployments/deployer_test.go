package infra_deployments_test

import (
	"fmt"
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/goplugin/plugin-starknet/integration-tests/common"
	"github.com/goplugin/plugin-starknet/ops/gauntlet"
	"github.com/goplugin/plugin-starknet/ops/utils"
	"github.com/goplugin/pluginv3.0/integration-tests/client"
)

const (
	L2RpcUrl = "https://alpha4-2.starknet.io"
	P2pPort  = "5001"
)

var (
	observationSource = `
			val [type="bridge" name="bridge-coinmetrics" requestData=<{"data": {"from":"PLI","to":"USD"}}>]
			parse [type="jsonparse" path="result"]
			val -> parse
			`
	juelsPerFeeCoinSource = `"""
			sum  [type="sum" values=<[451000]> ]
			sum
			"""
			`
)

func createKeys(testState *testing.T) ([]*client.PluginK8sClient, error) {
	urls := [][]string{
		// Node access params
		{"NODE_URL", "NODE_USER", "NODE_PASS"},
	}
	var clients []*client.PluginK8sClient

	for _, nodeUrl := range urls {
		u, _ := url.Parse(nodeUrl[0])
		c, err := client.NewPluginK8sClient(&client.PluginConfig{
			URL:        nodeUrl[0],
			Email:      nodeUrl[1],
			Password:   nodeUrl[2],
			InternalIP: u.Host,
		}, "", "")
		if err != nil {
			return nil, err
		}
		key, _ := c.MustReadP2PKeys()
		if key == nil {
			_, _, err = c.CreateP2PKey()
			require.NoError(testState, err)
		}
		clients = append(clients, c)
	}
	return clients, nil
}
func TestOCRBasic(testState *testing.T) {
	var err error
	t := &common.Test{}
	t.Common = common.New()
	t.Common.Default(testState)
	t.Cc = &common.PluginClient{}
	t.Common.P2PPort = P2pPort
	t.Cc.PluginNodes, err = createKeys(testState)
	require.NoError(testState, err)
	t.Cc.NKeys, _, err = client.CreateNodeKeysBundle(t.GetPluginNodes(), t.Common.ChainName, t.Common.ChainId)
	require.NoError(testState, err)
	for _, n := range t.Cc.PluginNodes {
		_, _, err = n.CreateStarkNetChain(&client.StarkNetChainAttributes{
			Type:    t.Common.ChainName,
			ChainID: t.Common.ChainId,
			Config:  client.StarkNetChainConfig{},
		})
		require.NoError(testState, err)
		_, _, err = n.CreateStarkNetNode(&client.StarkNetNodeAttributes{
			Name:    t.Common.ChainName,
			ChainID: t.Common.ChainId,
			Url:     L2RpcUrl,
		})
		require.NoError(testState, err)
	}
	t.Common.Testnet = true
	t.Common.L2RPCUrl = L2RpcUrl
	t.Sg, err = gauntlet.NewStarknetGauntlet(fmt.Sprintf("%s/", utils.ProjectRoot))
	require.NoError(testState, err, "Could not get a new gauntlet struct")
	err = t.Sg.SetupNetwork(t.Common.L2RPCUrl)
	require.NoError(testState, err, "Setting up gauntlet network should not fail")
	err = t.DeployGauntlet(0, 100000000000, 9, "auto", 1, 1)
	require.NoError(testState, err, "Deploying contracts should not fail")
	t.SetBridgeTypeAttrs(&client.BridgeTypeAttributes{
		Name: "bridge-coinmetrics",
		URL:  "ADAPTER_URL", // ADAPTER_URL e.g https://adapters.main.sand.cldev.sh/coinmetrics
	})

	err = t.Common.CreateJobsForContract(t.Cc, observationSource, juelsPerFeeCoinSource, t.OCRAddr, t.AccountAddresses)
	require.NoError(testState, err)
}
