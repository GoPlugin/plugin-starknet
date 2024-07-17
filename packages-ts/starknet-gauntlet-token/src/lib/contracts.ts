import { loadContract } from '@plugin/starknet-gauntlet'

export enum CONTRACT_LIST {
  TOKEN = 'token',
}

export const tokenContractLoader = () => loadContract('LinkToken')
