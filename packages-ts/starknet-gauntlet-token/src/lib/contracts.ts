import { loadContract } from '@plugin/starknet-gauntlet'

export enum CONTRACT_LIST {
  TOKEN = 'token',
}

export const tokenContractLoader = () => loadContract('plugin_token_v1_link_token_LinkToken')
