import { makeExecuteCommand, declareCommandConfig } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { CONTRACT_LIST, contractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  declareCommandConfig(CONTRACT_LIST.MULTISIG, CATEGORIES.MULTISIG, contractLoader),
)
