import { ExecuteCommandConfig, makeExecuteCommand, Validation } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { tokenContractLoader } from '../../lib/contracts'
import {
  IncreaseBalanceBaseConfig,
  IncreaseBalanceInput,
} from '@pluginv3.0/gauntlet-contracts-example'

type ContractInput = [number]

const makeContractInput = async (input: IncreaseBalanceInput): Promise<ContractInput> => {
  return [Number(input.balance)]
}

const commandConfig: ExecuteCommandConfig<IncreaseBalanceInput, ContractInput> = {
  ...IncreaseBalanceBaseConfig,
  makeContractInput: makeContractInput,
  loadContract: tokenContractLoader,
}

export default makeExecuteCommand(commandConfig)
