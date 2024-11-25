import { encoding } from '@plugin/gauntlet-contracts-ocr2'
import { feltsToBytes } from '@plugin/starknet-gauntlet'
import { BigNumberish } from 'starknet'

export const decodeOffchainConfigFromEventData = (
  data: BigNumberish[],
): encoding.OffchainConfig => {
  return encoding.deserializeConfig(feltsToBytes(data))
}
