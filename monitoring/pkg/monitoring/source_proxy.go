package monitoring

import (
	"context"
	"fmt"
	"math/big"

	caigotypes "github.com/smartcontractkit/caigo/types"

	relayMonitoring "github.com/goplugin/plugin-common/pkg/monitoring"

	"github.com/goplugin/plugin-starknet/relayer/pkg/plugin/ocr2"
)

type ProxyData struct {
	Answer *big.Int
}

func NewProxySourceFactory(
	ocr2Reader ocr2.OCR2Reader,
) relayMonitoring.SourceFactory {
	return &proxySourceFactory{
		ocr2Reader,
	}
}

type proxySourceFactory struct {
	ocr2Reader ocr2.OCR2Reader
}

func (s *proxySourceFactory) NewSource(
	_ relayMonitoring.ChainConfig,
	feedConfig relayMonitoring.FeedConfig,
) (relayMonitoring.Source, error) {
	return &proxySource{
		caigotypes.HexToHash(feedConfig.GetContractAddress()),
		s.ocr2Reader,
	}, nil
}

func (s *proxySourceFactory) GetType() string {
	return "proxy"
}

type proxySource struct {
	contractAddress caigotypes.Hash
	ocr2Reader      ocr2.OCR2Reader
}

func (s *proxySource) Fetch(ctx context.Context) (interface{}, error) {
	latestTransmission, err := s.ocr2Reader.LatestTransmissionDetails(ctx, s.contractAddress)
	if err != nil {
		return nil, fmt.Errorf("couldn't fetch latest_transmission_details: %w", err)
	}
	return ProxyData{
		Answer: latestTransmission.LatestAnswer,
	}, nil
}
