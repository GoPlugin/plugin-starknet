import { loadContract } from '@pluginv3.0/starknet-gauntlet'

export enum CONTRACT_LIST {
  OCR2 = 'Aggregator',
  ACCESS_CONTROLLER = 'AccessController',
  PROXY = 'AggregatorProxy',
  AGGREGATOR_CONSUMER = 'AggregatorConsumer',
}

export const ocr2ContractLoader = () => loadContract(CONTRACT_LIST.OCR2)
export const ocr2ProxyLoader = () => loadContract(CONTRACT_LIST.PROXY)
export const aggregatorConsumerLoader = () => loadContract(CONTRACT_LIST.AGGREGATOR_CONSUMER)
export const accessControllerContractLoader = () => loadContract(CONTRACT_LIST.ACCESS_CONTROLLER)
