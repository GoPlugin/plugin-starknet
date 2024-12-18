use plugin::emergency::sequencer_uptime_feed::ISequencerUptimeFeedDispatcherTrait;
use plugin::emergency::sequencer_uptime_feed::ISequencerUptimeFeedDispatcher;
use plugin::libraries::access_control::IAccessControllerDispatcherTrait;
use plugin::libraries::access_control::IAccessControllerDispatcher;
use plugin::ocr2::mocks::mock_aggregator::IMockAggregatorDispatcherTrait;
use plugin::ocr2::mocks::mock_aggregator::IMockAggregatorDispatcher;

use aggregator_consumer::ocr2::price_consumer::IAggregatorPriceConsumerDispatcherTrait;
use aggregator_consumer::ocr2::price_consumer::IAggregatorPriceConsumerDispatcher;

use starknet::contract_address_const;
use starknet::get_caller_address;
use starknet::ContractAddress;

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global, stop_cheat_caller_address_global
};

fn deploy_mock_aggregator(decimals: u8) -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    calldata.append(decimals.into());
    let (contract_address, _) = declare("MockAggregator").unwrap().deploy(@calldata).unwrap();
    contract_address
}

fn deploy_uptime_feed(initial_status: u128, owner_address: ContractAddress) -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    calldata.append(initial_status.into());
    calldata.append(owner_address.into());
    let (contract_address, _) = declare("SequencerUptimeFeed").unwrap().deploy(@calldata).unwrap();
    contract_address
}

fn deploy_price_consumer(
    uptime_feed_address: ContractAddress, aggregator_address: ContractAddress
) -> ContractAddress {
    let mut calldata = ArrayTrait::new();
    calldata.append(uptime_feed_address.into());
    calldata.append(aggregator_address.into());
    let (contract_address, _) = declare("AggregatorPriceConsumer")
        .unwrap()
        .deploy(@calldata)
        .unwrap();
    contract_address
}

#[test]
fn test_get_latest_price() {
    // Defines helper variables
    let owner = contract_address_const::<1>();
    let init_status = 0;
    let decimals = 18;

    // Deploys contracts
    let mock_aggregator_address = deploy_mock_aggregator(decimals);
    let uptime_feed_address = deploy_uptime_feed(init_status, owner);
    let price_consumer_address = deploy_price_consumer(
        uptime_feed_address, mock_aggregator_address
    );

    // Adds the price consumer contract to the sequencer uptime feed access control list
    // which allows the price consumer to call the get_latest_price function
    start_cheat_caller_address_global(owner);
    // start_prank(CheatTarget::All, owner);
    IAccessControllerDispatcher { contract_address: uptime_feed_address }
        .add_access(price_consumer_address);

    // The get_latest_price function returns the mock aggregator's latest round answer. At  
    // this point in the test, there is only one round that is initialized and that is the 
    // one that the sequencer uptime feed creates when it is deployed. In its constructor, 
    // a new round is initialized using its initial status as the round's answer, so the 
    // latest price should be the initial status that was passed into the sequencer uptime 
    // feed's constructor.
    start_cheat_caller_address_global(price_consumer_address);
    // start_prank(CheatTarget::All, price_consumer_address);
    let latest_price = IAggregatorPriceConsumerDispatcher {
        contract_address: price_consumer_address
    }
        .get_latest_price();
    assert(latest_price == init_status, 'latest price is incorrect');

    // Now let's update the round
    stop_cheat_caller_address_global();
    let answer = 1;
    let block_num = 12345;
    let observation_timestamp = 100000;
    let transmission_timestamp = 200000;
    IMockAggregatorDispatcher { contract_address: mock_aggregator_address }
        .set_latest_round_data(answer, block_num, observation_timestamp, transmission_timestamp);

    // This should now return the updated answer
    start_cheat_caller_address_global(price_consumer_address);
    let updated_latest_price = IAggregatorPriceConsumerDispatcher {
        contract_address: price_consumer_address
    }
        .get_latest_price();
    assert(updated_latest_price == answer, 'updated price is incorrect');
}

