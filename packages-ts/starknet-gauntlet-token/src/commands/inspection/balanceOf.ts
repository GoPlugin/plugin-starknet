import {
  InspectCommandConfig,
  IStarknetProvider,
  makeInspectionCommand,
  InspectUserInput,
  isValidAddress,
} from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { tokenContractLoader } from '../../lib/contracts'

type UserInput = {
  address: string
}

type ContractInput = string

type QueryResult = {
  balance: string
}

const makeUserInput = async (flags, args): Promise<InspectUserInput<UserInput, null>> => {
  if (flags.input) return flags.input as InspectUserInput<UserInput, null>

  return {
    input: {
      address: flags.address,
    },
  }
}

const makeContractInput = async (input: UserInput): Promise<ContractInput[]> => {
  if (!isValidAddress(input.address)) throw new Error(`Invalid account address: ${input.address}`)
  return [input.address]
}

const makeComparisionData = (provider: IStarknetProvider) => async (
  results: any[],
  input: null,
  contractAddress: string,
): Promise<{
  toCompare: null
  result: QueryResult
}> => {
  const [queryRes] = results
  const balance = queryRes

  return {
    toCompare: null,
    result: {
      balance: balance.toString(),
    },
  }
}

const commandConfig: InspectCommandConfig<UserInput, ContractInput, null, QueryResult> = {
  ux: {
    category: CATEGORIES.TOKEN,
    function: 'balance_of',
    examples: [
      `${CATEGORIES.TOKEN}:balance_of --network=<NETWORK> --address=<ACCOUNT_ADDRESS> <TOKEN_CONTRACT_ADDRESS>`,
    ],
  },
  queries: ['balance_of'],
  makeUserInput,
  makeContractInput,
  makeComparisionData,
  loadContract: tokenContractLoader,
}

export default makeInspectionCommand(commandConfig)
