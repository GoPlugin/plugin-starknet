import { makeExecuteCommand, upgradeCommandConfig } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { CONTRACT_LIST, uptimeFeedContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  upgradeCommandConfig(
    CONTRACT_LIST.SEQUENCER_UPTIME_FEED,
    CATEGORIES.SEQUENCER_UPTIME_FEED,
    uptimeFeedContractLoader,
  ),
)
