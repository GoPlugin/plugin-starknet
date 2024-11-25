package smoke_test

import (
	"flag"
	"fmt"
	"maps"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
	"go.uber.org/zap/zapcore"

	"github.com/goplugin/plugin-testing-framework/logging"
	"github.com/goplugin/pluginv3.0/integration-tests/actions"
	"github.com/goplugin/pluginv3.0/integration-tests/docker/test_env"

	"github.com/goplugin/plugin-starknet/integration-tests/common"
	tc "github.com/goplugin/plugin-starknet/integration-tests/testconfig"
	"github.com/goplugin/plugin-starknet/ops/gauntlet"
	"github.com/goplugin/plugin-starknet/ops/utils"
)

var (
	keepAlive bool
	decimals  = 9
)

func init() {
	flag.BoolVar(&keepAlive, "keep-alive", false, "enable to keep the cluster alive")
}

func TestOCRBasicSoak(t *testing.T) {
	for _, test := range []struct {
		name string
		env  map[string]string
	}{
		{name: "embedded"},
		{name: "plugins", env: map[string]string{
			"CL_MEDIAN_CMD": "plugin-feeds",
			"CL_SOLANA_CMD": "plugin-solana",
		}},
	} {
		config, err := tc.GetConfig("Soak", tc.OCR2)
		if err != nil {
			t.Fatal(err)
		}
		err = os.Setenv("PLUGIN_ENV_USER", *config.Common.User)
		require.NoError(t, err, "Could not set PLUGIN_ENV_USER")
		err = os.Setenv("INTERNAL_DOCKER_REPO", *config.Common.InternalDockerRepo)
		require.NoError(t, err, "Could not set INTERNAL_DOCKER_REPO")
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			logging.Init()
			//
			state, err := common.NewOCRv2State(t, "soak-ocr2", &config)
			require.NoError(t, err, "Could not setup the ocrv2 state")

			// K8s specific config and cleanup
			if *config.Common.InsideK8s {
				t.Cleanup(func() {
					if err = actions.TeardownSuite(t, nil, state.Common.Env, state.PluginNodesK8s, nil, zapcore.PanicLevel, nil); err != nil {
						state.TestConfig.L.Error().Err(err).Msg("Error tearing down environment")
					}
				})
			}
			if len(test.env) > 0 {
				state.Common.TestEnvDetails.NodeOpts = append(state.Common.TestEnvDetails.NodeOpts, func(n *test_env.ClNode) {
					if n.ContainerEnvs == nil {
						n.ContainerEnvs = map[string]string{}
					}
					maps.Copy(n.ContainerEnvs, test.env)
				})
			}
			state.DeployCluster()

			if state.Common.Env.WillUseRemoteRunner() {
				return
			}

			state.Clients.GauntletClient, err = gauntlet.NewStarknetGauntlet(fmt.Sprintf("%s/", utils.ProjectRoot))
			require.NoError(t, err, "Setting up gauntlet should not fail")
			err = state.Clients.GauntletClient.SetupNetwork(state.Common.RPCDetails.RPCL2External, state.Account.Account, state.Account.PrivateKey)
			require.NoError(t, err, "Setting up gauntlet network should not fail")
			err = state.DeployGauntlet(0, 100000000000, decimals, "auto", 1, 1)
			require.NoError(t, err, "Deploying contracts should not fail")

			state.SetUpNodes()

			err = state.ValidateRounds(*config.OCR2.NumberOfRounds, true)
			require.NoError(t, err, "Validating round should not fail")
		})
	}
}
