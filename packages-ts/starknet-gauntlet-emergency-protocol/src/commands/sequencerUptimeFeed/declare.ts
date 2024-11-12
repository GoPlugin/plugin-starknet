import { makeExecuteCommand, declareCommandConfig } from '@plugin/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { CONTRACT_LIST, uptimeFeedContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  declareCommandConfig(
    CONTRACT_LIST.SEQUENCER_UPTIME_FEED,
    CATEGORIES.SEQUENCER_UPTIME_FEED,
    uptimeFeedContractLoader,
  ),
)
