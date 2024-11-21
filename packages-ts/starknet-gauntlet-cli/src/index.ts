import {
  executeCommands as OCR2ExecuteCommands,
  inspectionCommands as OCR2InspectionCommands,
} from '@pluginv3.0/starknet-gauntlet-ocr2'
import {
  executeCommands as ExampleExecuteCommands,
  inspectionCommands as ExampleInspectionsCommands,
} from '@pluginv3.0/starknet-gauntlet-example'
import { Commands as OZCommands } from '@pluginv3.0/starknet-gauntlet-oz'
import {
  L2Commands as L2StarkgateCommands,
  InspectionCommands as StarkgateInspectionCommands,
} from '@pluginv3.0/starknet-gauntlet-token'
import { Commands as ArgentCommands } from '@pluginv3.0/starknet-gauntlet-argent'
import {
  L1Commands as L1EmergencyProtocolCommands,
  L2Commands as L2EmergencyProtocolCommands,
  L2InspectionCommands as L2EmergencyProtocolInspectionCommands,
} from '@pluginv3.0/starknet-gauntlet-emergency-protocol'
import {
  executeCommands as MultisigExecuteCommands,
  inspectionCommands as MultisigInspectionCommands,
  wrapCommand as multisigWrapCommand,
} from '@pluginv3.0/starknet-gauntlet-multisig'

import { executeCLI } from '@pluginv3.0/gauntlet-core'
import { existsSync } from 'fs'
import path from 'path'
import { io, logger, prompt } from '@pluginv3.0/gauntlet-core/dist/utils'
import {
  CommandCtor,
  Dependencies,
  Env,
  ExecuteCommandInstance,
  InspectCommandInstance,
  makeProvider,
  makeWallet as makeDefaultWallet,
} from '@pluginv3.0/starknet-gauntlet'
import {
  EVMExecuteCommandInstance,
  CommandCtor as EVMCommandCtor,
  makeWallet as EVMMakeWallet,
  makeProvider as EVMMakeProvider,
  EVMDependencies,
} from '@pluginv3.0/evm-gauntlet'
import { makeWallet as makeLedgerWallet } from '@pluginv3.0/starknet-gauntlet-ledger'

export const noopPrompt: typeof prompt = async () => {}

const registerExecuteCommand = <UI, CI>(
  registerCommand: (deps: Dependencies) => CommandCtor<ExecuteCommandInstance<UI, CI>>,
  emptyPrompt = false,
) => {
  const deps: Dependencies | Omit<Dependencies, 'makeWallet'> = {
    logger: logger,
    prompt: emptyPrompt ? noopPrompt : prompt,
    makeEnv: (flags) => {
      const env: Env = {
        providerUrl: process.env.NODE_URL,
        pk: process.env.PRIVATE_KEY,
        publicKey: process.env.PUBLIC_KEY,
        account: process.env.ACCOUNT,
        multisig: process.env.MULTISIG,
        billingAccessController: process.env.BILLING_ACCESS_CONTROLLER,
        link: process.env.PLI,
        secret: flags.secret || process.env.SECRET,
        randomSecret: flags.randomSecret || process.env.RANDOM_SECRET,
        withLedger: !!flags.withLedger || !!process.env.WITH_LEDGER,
        ledgerPath: (flags.ledgerPath as string) || process.env.LEDGER_PATH,
      }
      return env
    },
    makeProvider: makeProvider,
    makeWallet: async (env: Env) => {
      if (env.withLedger) {
        return makeLedgerWallet(env)
      }

      return makeDefaultWallet(env)
    },
  }
  return registerCommand(deps)
}

const registerEVMExecuteCommand = <UI, CI extends Iterable<any>>(
  registerCommand: (deps: EVMDependencies) => EVMCommandCtor<EVMExecuteCommandInstance<UI, CI>>,
  gauntletConfig,
) => {
  const deps: EVMDependencies = {
    logger: logger,
    prompt: prompt,
    makeEnv: (flags) => {
      return {
        providerUrl: process.env.NODE_URL,
        pk: process.env.PRIVATE_KEY,
      }
    },
    makeProvider: EVMMakeProvider,
    makeWallet: EVMMakeWallet,
  }
  return registerCommand(deps)
}

const registerInspectionCommand = <QueryResult>(
  registerCommand: (
    deps: Omit<Dependencies, 'makeWallet'>,
  ) => CommandCtor<InspectCommandInstance<QueryResult>>,
) => {
  const deps: Omit<Dependencies, 'makeWallet'> = {
    logger: logger,
    prompt: prompt,
    makeEnv: (flags) => {
      const env: Env = {
        providerUrl: process.env.NODE_URL,
      }
      return env
    },
    makeProvider: makeProvider,
  }
  return registerCommand(deps)
}

const L1ExecuteCommands: any[] = [...L1EmergencyProtocolCommands]
const L2ExecuteCommands = [
  ...OCR2ExecuteCommands,
  ...ExampleExecuteCommands,
  ...OZCommands,
  ...L2StarkgateCommands,
  ...ArgentCommands,
  ...MultisigExecuteCommands,
  ...L2EmergencyProtocolCommands,
]

const msigCommands = L2ExecuteCommands.map((c) => registerExecuteCommand(c, true)).map(
  multisigWrapCommand,
)
const unregistedInspectionCommands = [
  ...ExampleInspectionsCommands,
  ...MultisigInspectionCommands,
  ...OCR2InspectionCommands,
  ...L2EmergencyProtocolInspectionCommands,
  ...StarkgateInspectionCommands,
]

const commands = {
  custom: [
    ...L2ExecuteCommands.map((c) => registerExecuteCommand(c)),
    ...L1ExecuteCommands.map((c) => registerEVMExecuteCommand(c, null)),
    ...msigCommands.map((c) => registerExecuteCommand(c)),
    ...unregistedInspectionCommands.map(registerInspectionCommand),
  ],
  loadDefaultFlags: () => ({}),
  abstract: {
    findPolymorphic: () => undefined,
    makeCommand: () => undefined,
  },
}
;(async () => {
  try {
    const networkPossiblePaths = [
      path.join(process.cwd(), 'networks'),
      path.join(__dirname, '../networks'),
    ]
    const networkPath = networkPossiblePaths.filter((networkPath) => existsSync(networkPath))[0]
    const result = await executeCLI(commands, networkPath)
    if (result) {
      io.saveJSON(result, process.env['REPORT_NAME'] ? process.env['REPORT_NAME'] : 'report')
    }
    process.exit(0)
  } catch (e) {
    console.log(e)
    console.log('Starknet Command execution error', e.message)
    process.exitCode = 1
  }
})()
