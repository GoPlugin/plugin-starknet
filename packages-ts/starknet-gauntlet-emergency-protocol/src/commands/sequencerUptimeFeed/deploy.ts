import {
  ExecuteCommandConfig,
  isValidAddress,
  makeExecuteCommand,
} from '@pluginv3.0/starknet-gauntlet'
import { CONTRACT_LIST, uptimeFeedContractLoader } from '../../lib/contracts'
import { CATEGORIES } from '../../lib/categories'

type ContractInput = [initial_status: number, owner_address: string]

export interface UserInput {
  initialStatus: number
  owner?: string
}

const makeContractInput = async (input: UserInput): Promise<ContractInput> => {
  return [input.initialStatus, input.owner]
}

const validateOwner = async (input) => {
  if (!isValidAddress(input.owner)) {
    throw new Error(`Invalid Owner Address: ${input.owner}`)
  }
  return true
}

const validateInitialStatus = async (input) => {
  const status = Number(input.initialStatus)
  if (status !== 1 && status !== 0) {
    throw new Error(`Invalid Initial Status: ${input.initialStatus}`)
  }
  return true
}

const makeUserInput = async (flags, args, env): Promise<UserInput> => {
  if (flags.input) return flags.input as UserInput
  return {
    owner: flags.owner || env.account,
    initialStatus: flags.initialStatus,
  }
}

const commandConfig: ExecuteCommandConfig<UserInput, ContractInput> = {
  contractId: CONTRACT_LIST.SEQUENCER_UPTIME_FEED,
  category: CATEGORIES.SEQUENCER_UPTIME_FEED,
  action: 'deploy',
  ux: {
    description: 'Deploys a SequencerUptimeFeed contract',
    examples: [
      `${CATEGORIES.SEQUENCER_UPTIME_FEED}:deploy --initialStatus=<INITIAL_STATUS> --network=<NETWORK>`,
      `${CATEGORIES.SEQUENCER_UPTIME_FEED}:deploy --initialStatus=<INITIAL_STATUS> --owner=<STARKNET_ADDRESS> --network=<NETWORK>`,
    ],
  },
  makeUserInput,
  makeContractInput,
  validations: [validateOwner, validateInitialStatus],
  loadContract: uptimeFeedContractLoader,
}

export default makeExecuteCommand(commandConfig)
