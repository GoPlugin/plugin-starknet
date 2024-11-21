import { loadContract } from '@pluginv3.0/starknet-gauntlet'

export enum CONTRACT_LIST {
  TOKEN = 'token',
}

export const tokenContractLoader = () => loadContract('LinkToken')
