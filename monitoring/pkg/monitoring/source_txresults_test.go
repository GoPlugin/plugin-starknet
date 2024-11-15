package monitoring

import (
	"context"
	"testing"

	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	starknetutils "github.com/NethermindEth/starknet.go/utils"
	relayMonitoring "github.com/goplugin/plugin-common/pkg/monitoring"

	"github.com/goplugin/plugin-starknet/relayer/pkg/plugin/ocr2"
	ocr2Mocks "github.com/goplugin/plugin-starknet/relayer/pkg/plugin/ocr2/mocks"
)

func TestTxResultsSource(t *testing.T) {
	// This test makes sure that the mapping between the response from the ocr2.Client
	// method calls and the output of the TxResults source is correct.

	chainConfig := generateChainConfig()
	feedConfig := generateFeedConfig()

	feedContractAddressFelt, err := starknetutils.HexToFelt(feedConfig.ContractAddress)
	require.NoError(t, err)

	ocr2Reader := ocr2Mocks.NewOCR2Reader(t)
	ocr2Reader.On(
		"LatestRoundData",
		mock.Anything, // ctx
		feedContractAddressFelt,
	).Return(ocr2ClientLatestRoundDataResponseForTxResults1, nil).Once()
	ocr2Reader.On(
		"LatestRoundData",
		mock.Anything, // ctx
		feedContractAddressFelt,
	).Return(ocr2ClientLatestRoundDataResponseForTxResults2, nil).Once()

	factory := NewTxResultsSourceFactory(ocr2Reader)
	source, err := factory.NewSource(chainConfig, feedConfig)
	require.NoError(t, err)
	// First call identifies no new transactions.
	rawTxResults, err := source.Fetch(context.Background())
	require.NoError(t, err)
	txResults, ok := rawTxResults.(relayMonitoring.TxResults)
	require.True(t, ok)
	require.Equal(t, txResults.NumSucceeded, uint64(0))
	require.Equal(t, txResults.NumFailed, uint64(0))
	// Second call identifies new transactions
	rawTxResults, err = source.Fetch(context.Background())
	require.NoError(t, err)
	txResults, ok = rawTxResults.(relayMonitoring.TxResults)
	require.True(t, ok)
	require.Equal(t, txResults.NumSucceeded, uint64(1))
	require.Equal(t, txResults.NumFailed, uint64(0))
}

var (
	ocr2ClientLatestRoundDataResponseForTxResults1 = ocr2.RoundData{
		RoundID: 100,
	}
	ocr2ClientLatestRoundDataResponseForTxResults2 = ocr2.RoundData{
		RoundID: 101,
	}
)
