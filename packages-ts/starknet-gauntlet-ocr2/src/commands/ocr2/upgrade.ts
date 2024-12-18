import { makeExecuteCommand, upgradeCommandConfig } from '@pluginv3.0/starknet-gauntlet'
import { CATEGORIES } from '../../lib/categories'
import { ocr2ContractLoader } from '../../lib/contracts'

export default makeExecuteCommand(
  upgradeCommandConfig(CATEGORIES.OCR2, CATEGORIES.OCR2, ocr2ContractLoader),
)
