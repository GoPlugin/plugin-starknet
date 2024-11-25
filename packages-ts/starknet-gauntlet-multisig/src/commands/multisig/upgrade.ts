import { makeExecuteCommand, upgradeCommandConfig } from '@plugin/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { contractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  upgradeCommandConfig(CATEGORIES.MULTISIG, CATEGORIES.MULTISIG, contractLoader),
)
