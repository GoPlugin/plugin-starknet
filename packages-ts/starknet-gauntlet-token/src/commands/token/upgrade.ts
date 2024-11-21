import { makeExecuteCommand, upgradeCommandConfig } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { tokenContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  upgradeCommandConfig(CATEGORIES.TOKEN, CATEGORIES.TOKEN, tokenContractLoader),
)
