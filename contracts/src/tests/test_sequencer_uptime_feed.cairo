use starknet::ContractAddress;
use starknet::EthAddress;
use starknet::contract_address_const;
use starknet::class_hash::class_hash_const;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::syscalls::deploy_syscall;
use starknet::testing::set_caller_address;
use starknet::testing::set_contract_address;

use array::ArrayTrait;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use core::result::ResultTrait;

use plugin::emergency::sequencer_uptime_feed::SequencerUptimeFeed;
use plugin::libraries::access_control::{
    IAccessController, IAccessControllerDispatcher, IAccessControllerDispatcherTrait
};
use plugin::ocr2::aggregator_proxy::{
    IAggregatorProxy, IAggregatorProxyDispatcher, IAggregatorProxyDispatcherTrait
};
use plugin::ocr2::aggregator_proxy::AggregatorProxy;
use plugin::ocr2::aggregator_proxy::AggregatorProxy::AggregatorProxyImpl;
use plugin::tests::test_ownable::should_implement_ownable;
use plugin::tests::test_access_controller::should_implement_access_control;

use plugin::emergency::sequencer_uptime_feed::{
    ISequencerUptimeFeed, ISequencerUptimeFeedDispatcher, ISequencerUptimeFeedDispatcherTrait
};

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global, stop_cheat_caller_address_global
};


fn PROXY() -> AggregatorProxy::ContractState {
    AggregatorProxy::contract_state_for_testing()
}

fn STATE() -> SequencerUptimeFeed::ContractState {
    SequencerUptimeFeed::contract_state_for_testing()
}

fn setup() -> (ContractAddress, ContractAddress, ISequencerUptimeFeedDispatcher) {
    let account: ContractAddress = contract_address_const::<777>();

    start_cheat_caller_address_global(account);

    // Deploy seqeuencer uptime feed
    let calldata = array![0, // initial status
     account.into() // owner
    ];

    let (sequencerFeedAddr, _) = declare("SequencerUptimeFeed").unwrap().deploy(@calldata).unwrap();

    let sequencerUptimeFeed = ISequencerUptimeFeedDispatcher {
        contract_address: sequencerFeedAddr
    };

    (account, sequencerFeedAddr, sequencerUptimeFeed)
}

#[test]
fn test_ownable() {
    let (account, sequencerFeedAddr, _) = setup();
    should_implement_ownable(sequencerFeedAddr, account);
}

#[test]
fn test_access_control() {
    let (account, sequencerFeedAddr, _) = setup();
    should_implement_access_control(sequencerFeedAddr, account);
}

#[test]
#[should_panic()]
fn test_set_l1_sender_not_owner() {
    let (_, _, sequencerUptimeFeed) = setup();
    start_cheat_caller_address_global(contract_address_const::<111>());
    sequencerUptimeFeed.set_l1_sender(EthAddress { address: 789 });
}

#[test]
fn test_set_l1_sender() {
    let (owner, _, sequencerUptimeFeed) = setup();
    start_cheat_caller_address_global(owner);
    sequencerUptimeFeed.set_l1_sender(EthAddress { address: 789 });
    assert(sequencerUptimeFeed.l1_sender().address == 789, 'l1_sender should be set to 789');
}

#[test]
#[should_panic(expected: ('user does not have read access',))]
fn test_latest_round_data_no_access() {
    let (owner, sequencerFeedAddr, _) = setup();
    let mut proxy = PROXY();
    AggregatorProxy::constructor(ref proxy, owner, sequencerFeedAddr);
    AggregatorProxyImpl::latest_round_data(@proxy);
}

#[test]
#[should_panic(expected: ('user does not have read access',))]
fn test_latest_answer_no_access() {
    let (owner, sequencerFeedAddr, _) = setup();
    let mut proxy = PROXY();
    AggregatorProxy::constructor(ref proxy, owner, sequencerFeedAddr);
    AggregatorProxyImpl::latest_answer(@proxy);
}

#[test]
fn test_aggregator_proxy_response() {
    let (owner, sequencerFeedAddr, _) = setup();
    start_cheat_caller_address_global(owner);
    let contract = IAccessControllerDispatcher { contract_address: sequencerFeedAddr };
    contract.add_access(owner);

    let proxy = IAggregatorProxyDispatcher { contract_address: sequencerFeedAddr };

    // latest round data
    let latest_round_data = proxy.latest_round_data();
    assert(latest_round_data.answer == 0, 'latest_round_data should be 0');

    // latest answer 
    let latest_answer = proxy.latest_answer();
    assert(latest_answer == 0, 'latest_answer should be 0');

    // description
    let description = proxy.description();
    assert(description == 'L2 Sequencer Uptime Status Feed', 'description does not match');

    // decimals
    let decimals = proxy.decimals();
    assert(decimals == 0, 'decimals should be 0');
}
