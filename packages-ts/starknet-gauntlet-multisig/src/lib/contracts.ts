import { loadContract } from '@plugin/starknet-gauntlet'

export enum CONTRACT_LIST {
  MULTISIG = 'Multisig',
}

export const contractLoader = () => loadContract(CONTRACT_LIST.MULTISIG)
