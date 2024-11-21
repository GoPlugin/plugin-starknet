import { loadContract } from '@pluginv3.0/starknet-gauntlet'

export enum CONTRACT_LIST {
  EXAMPLE = 'example',
}

export const tokenContractLoader = () => loadContract(CONTRACT_LIST.EXAMPLE)
