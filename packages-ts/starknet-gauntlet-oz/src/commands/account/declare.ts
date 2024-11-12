import { makeExecuteCommand, declareCommandConfig } from '@plugin/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { CONTRACT_LIST, accountContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  declareCommandConfig(CONTRACT_LIST.ACCOUNT, CATEGORIES.ACCOUNT, accountContractLoader),
)
