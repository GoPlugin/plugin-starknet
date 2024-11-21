import fs from 'fs'
import { json } from 'starknet'

export enum CONTRACT_LIST {
  ACCOUNT = 'Account',
}

export const accountContractLoader = () => {
  return {
    contract: json.parse(
      fs.readFileSync(
        `${__dirname}/../../../../node_modules/@pluginv3.0-dev/starkgate-open-zeppelin/artifacts/0.6.1/Account.cairo/Account.json`,
        'utf8',
      ),
    ),
  }
}
