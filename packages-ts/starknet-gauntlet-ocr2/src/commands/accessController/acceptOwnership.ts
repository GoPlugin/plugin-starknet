import { makeExecuteCommand, acceptOwnershipCommandConfig } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { accessControllerContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  acceptOwnershipCommandConfig(
    CATEGORIES.ACCESS_CONTROLLER,
    CATEGORIES.ACCESS_CONTROLLER,
    accessControllerContractLoader,
  ),
)