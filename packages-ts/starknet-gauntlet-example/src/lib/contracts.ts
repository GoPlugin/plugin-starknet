import { loadContract } from '@plugin/starknet-gauntlet'

export enum CONTRACT_LIST {
  EXAMPLE = 'example',
}

export const tokenContractLoader = () => loadContract(CONTRACT_LIST.EXAMPLE)
