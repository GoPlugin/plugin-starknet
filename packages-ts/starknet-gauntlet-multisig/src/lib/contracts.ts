import { loadContract } from '@pluginv3.0/starknet-gauntlet'

export enum CONTRACT_LIST {
  MULTISIG = 'Multisig',
}

export const contractLoader = () => loadContract(CONTRACT_LIST.MULTISIG)
