import { encoding } from '@pluginv3.0/gauntlet-contracts-ocr2'
import { feltsToBytes } from '@pluginv3.0/starknet-gauntlet'
import { BigNumberish } from 'starknet'

export const decodeOffchainConfigFromEventData = (
  data: BigNumberish[],
): encoding.OffchainConfig => {
  return encoding.deserializeConfig(feltsToBytes(data))
}
