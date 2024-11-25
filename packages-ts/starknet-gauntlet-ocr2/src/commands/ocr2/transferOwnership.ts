import { makeExecuteCommand, transferOwnershipCommandConfig } from '@plugin/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { ocr2ContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  transferOwnershipCommandConfig(CATEGORIES.OCR2, CATEGORIES.OCR2, ocr2ContractLoader),
)
