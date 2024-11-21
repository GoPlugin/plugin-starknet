import {
  ExecuteCommandConfig,
  makeExecuteCommand,
  isValidAddress,
} from '@pluginv3.0/starknet-gauntlet'

export const validateClassHash = async (input) => {
  if (isValidAddress(input.classHash) || input.classHash === undefined) {
    return true
  }
  throw new Error(`Invalid Class Hash: ${input.classHash}`)
}
