use plugin::multisig::IMultisigDispatcherTrait;
use core::traits::Into;
use starknet::class_hash_const;
use starknet::contract_address_const;
use starknet::syscalls::deploy_syscall;
use starknet::testing::set_caller_address;
use starknet::testing::set_contract_address;
use starknet::Felt252TryIntoClassHash;

use array::ArrayTrait;
use option::OptionTrait;
use result::ResultTrait;
use traits::TryInto;

use plugin::multisig::assert_unique_values;
use plugin::multisig::Multisig;
use plugin::multisig::Multisig::{MultisigImpl, UpgradeableImpl};
use plugin::multisig::{IMultisigDispatcher};

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global,
    stop_cheat_caller_address_global, cheat_caller_address, CheatSpan
};

fn STATE() -> Multisig::ContractState {
    Multisig::contract_state_for_testing()
}

fn sample_calldata() -> Array::<felt252> {
    array![1, 2, 32]
}

#[test]
fn test_assert_unique_values_empty() {
    let a = ArrayTrait::<felt252>::new();
    assert_unique_values(@a);
}

#[test]
fn test_assert_unique_values_no_duplicates() {
    let a = array![1, 2, 3];
    assert_unique_values(@a);
}

#[test]
#[should_panic]
fn test_assert_unique_values_with_duplicate() {
    let a = array![1, 2, 3, 3];
    assert_unique_values(@a);
}

#[test]
fn test_is_signer_true() {
    let mut state = STATE();
    let signer = contract_address_const::<1>();
    let mut signers = ArrayTrait::new();
    signers.append(signer);
    Multisig::constructor(ref state, :signers, threshold: 1);
    assert(MultisigImpl::is_signer(@state, signer), 'should be signer');
}

#[test]
fn test_is_signer_false() {
    let mut state = STATE();
    let not_signer = contract_address_const::<2>();
    let mut signers = ArrayTrait::new();
    signers.append(contract_address_const::<1>());
    Multisig::constructor(ref state, :signers, threshold: 1);
    assert(!MultisigImpl::is_signer(@state, not_signer), 'should be signer');
}

#[test]
fn test_signer_len() {
    let mut state = STATE();
    let mut signers = ArrayTrait::new();
    signers.append(contract_address_const::<1>());
    signers.append(contract_address_const::<2>());
    Multisig::constructor(ref state, :signers, threshold: 1);
    assert(MultisigImpl::get_signers_len(@state) == 2, 'should equal 2 signers');
}

#[test]
fn test_get_signers() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];

    Multisig::constructor(ref state, :signers, threshold: 1);
    let returned_signers = MultisigImpl::get_signers(@state);
    assert(returned_signers.len() == 2, 'should match signers length');
    assert(*returned_signers.at(0) == signer1, 'should match signer 1');
    assert(*returned_signers.at(1) == signer2, 'should match signer 2');
}

#[test]
fn test_get_threshold() {
    let mut state = STATE();
    let mut signers = ArrayTrait::new();
    signers.append(contract_address_const::<1>());
    signers.append(contract_address_const::<2>());
    Multisig::constructor(ref state, :signers, threshold: 1);
    assert(MultisigImpl::get_threshold(@state) == 1, 'should equal threshold of 1');
}

#[test]
fn test_submit_transaction() {
    let mut state = STATE();
    let signer = contract_address_const::<1>();
    let signers = array![signer];
    Multisig::constructor(ref state, :signers, threshold: 1);

    start_cheat_caller_address_global(signer);
    let to = contract_address_const::<42>();
    let function_selector = 10;
    MultisigImpl::submit_transaction(
        ref state, :to, :function_selector, calldata: sample_calldata()
    );

    let (transaction, _) = MultisigImpl::get_transaction(@state, 0);
    assert(transaction.to == to, 'should match target address');
    assert(transaction.function_selector == function_selector, 'should match function selector');
    assert(transaction.calldata_len == sample_calldata().len(), 'should match calldata length');
    assert(!transaction.executed, 'should not be executed');
    assert(transaction.confirmations == 0, 'should not have confirmations');
// TODO: compare calldata when loops are supported
}

#[test]
#[should_panic]
fn test_submit_transaction_not_signer() {
    let mut state = STATE();
    let signer = contract_address_const::<1>();
    let signers = array![signer];
    Multisig::constructor(ref state, :signers, threshold: 1);

    start_cheat_caller_address_global(contract_address_const::<3>());
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
}

#[test]
fn test_confirm_transaction() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];
    Multisig::constructor(ref state, :signers, threshold: 2);

    start_cheat_caller_address_global(signer1);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);

    assert(MultisigImpl::is_confirmed(@state, nonce: 0, signer: signer1), 'should be confirmed');
    assert(
        !MultisigImpl::is_confirmed(@state, nonce: 0, signer: signer2), 'should not be confirmed'
    );
    let (transaction, _) = MultisigImpl::get_transaction(@state, 0);
    assert(transaction.confirmations == 1, 'should have confirmation');
}

#[test]
#[should_panic]
fn test_confirm_transaction_not_signer() {
    let mut state = STATE();
    let signer = contract_address_const::<1>();
    let not_signer = contract_address_const::<2>();
    let signers = array![signer];
    Multisig::constructor(ref state, :signers, threshold: 1);
    start_cheat_caller_address_global(signer);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    start_cheat_caller_address_global(not_signer);
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
}

#[test]
fn test_revoke_confirmation() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];
    Multisig::constructor(ref state, :signers, threshold: 2);
    start_cheat_caller_address_global(signer1);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);

    MultisigImpl::revoke_confirmation(ref state, nonce: 0);

    assert(
        !MultisigImpl::is_confirmed(@state, nonce: 0, signer: signer1), 'should not be confirmed'
    );
    assert(
        !MultisigImpl::is_confirmed(@state, nonce: 0, signer: signer2), 'should not be confirmed'
    );
    let (transaction, _) = MultisigImpl::get_transaction(@state, 0);
    assert(transaction.confirmations == 0, 'should not have confirmation');
}

#[test]
#[should_panic]
fn test_revoke_confirmation_not_signer() {
    let mut state = STATE();
    let signer = contract_address_const::<1>();
    let not_signer = contract_address_const::<2>();
    let mut signers = array![signer];
    Multisig::constructor(ref state, :signers, threshold: 2);
    start_cheat_caller_address_global(signer);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
    start_cheat_caller_address_global(not_signer);
    MultisigImpl::revoke_confirmation(ref state, nonce: 0);
}

#[test]
#[should_panic]
fn test_execute_confirmation_below_threshold() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];

    Multisig::constructor(ref state, :signers, threshold: 2);
    start_cheat_caller_address_global(signer1);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
    MultisigImpl::execute_transaction(ref state, nonce: 0);
}

#[test]
#[should_panic(expected: ('only multisig allowed',))]
fn test_upgrade_not_multisig() {
    let mut state = STATE();
    let account = contract_address_const::<777>();
    start_cheat_caller_address_global(account);
    UpgradeableImpl::upgrade(ref state, class_hash_const::<1>())
}

#[test]
fn test_execute() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];
    Multisig::constructor(ref state, :signers, threshold: 2);

    let calldata = ArrayTrait::new();

    let (test_address, _) = declare("MockMultisigTarget").unwrap().deploy(@calldata).unwrap();

    start_cheat_caller_address_global(signer1);
    let increment_calldata = array![42, 100];
    MultisigImpl::submit_transaction(
        ref state,
        to: test_address,
        // increment()
        function_selector: 0x7a44dde9fea32737a5cf3f9683b3235138654aa2d189f6fe44af37a61dc60d,
        calldata: increment_calldata,
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
    start_cheat_caller_address_global(signer2);
    MultisigImpl::confirm_transaction(ref state, nonce: 0);

    let response = MultisigImpl::execute_transaction(ref state, nonce: 0);
    assert(response.len() == 3, 'expected response length 3');
    assert(*response.at(0) == 2, 'expected array length 2');
    assert(*response.at(1) == 43, 'expected array value 43');
    assert(*response.at(2) == 101, 'expected array value 101');
}

#[test]
#[should_panic(expected: ('invalid signer',))]
fn test_execute_not_signer() {
    let mut state = STATE();
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];
    Multisig::constructor(ref state, :signers, threshold: 2);
    start_cheat_caller_address_global(signer1);
    MultisigImpl::submit_transaction(
        ref state,
        to: contract_address_const::<42>(),
        function_selector: 10,
        calldata: sample_calldata(),
    );
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
    start_cheat_caller_address_global(signer2);
    MultisigImpl::confirm_transaction(ref state, nonce: 0);
    start_cheat_caller_address_global(contract_address_const::<3>());
    MultisigImpl::execute_transaction(ref state, nonce: 0);
}

#[test]
#[should_panic(expected: ('transaction invalid',))]
fn test_execute_after_set_signers() {
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signer3 = contract_address_const::<3>();
    let signers = array![signer1, signer2];
    let init_threshold: usize = 2;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    start_cheat_caller_address_global(signer1);
    multisig
        .submit_transaction(
            to: contract_address_const::<42>(), function_selector: 10, calldata: sample_calldata(),
        );
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(signer2);
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(multisig_address);
    let new_signers = array![signer2, signer3];
    multisig.set_signers(new_signers);
    start_cheat_caller_address_global(signer2);
    multisig.execute_transaction(nonce: 0);
}

#[test]
#[should_panic(expected: ('transaction invalid',))]
fn test_execute_after_set_signers_and_threshold() {
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signer3 = contract_address_const::<3>();
    let signers = array![signer1, signer2];
    let init_threshold: usize = 2;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    // Multisig::constructor(ref state, :signers, threshold: 2);
    start_cheat_caller_address_global(signer1);
    multisig
        .submit_transaction(
            to: contract_address_const::<42>(), function_selector: 10, calldata: sample_calldata(),
        );
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(signer2);
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(multisig_address);
    let new_signers = array![signer2, signer3];
    multisig.set_signers_and_threshold(new_signers, 1);
    start_cheat_caller_address_global(signer2);
    multisig.execute_transaction(nonce: 0);
}

#[test]
#[should_panic(expected: ('transaction invalid',))]
fn test_execute_after_set_threshold() {
    let signer1 = contract_address_const::<1>();
    let signer2 = contract_address_const::<2>();
    let signers = array![signer1, signer2];
    let init_threshold: usize = 2;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    start_cheat_caller_address_global(signer1);
    multisig
        .submit_transaction(
            to: contract_address_const::<42>(), function_selector: 10, calldata: sample_calldata(),
        );
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(signer2);
    multisig.confirm_transaction(nonce: 0);
    start_cheat_caller_address_global(multisig_address);
    multisig.set_threshold(1);
    start_cheat_caller_address_global(signer1);
    multisig.execute_transaction(nonce: 0);
}

// test set_threshold (non-recursive)
#[test]
fn test_set_threshold() {
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let s3 = contract_address_const::<3>();
    let signers = array![s1, s2, s3];
    let init_threshold: usize = 3;
    let new_threshold: usize = 2;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };
    assert(multisig.get_threshold() == init_threshold, 'invalid init threshold');
    start_cheat_caller_address_global(multisig_address);
    multisig.set_threshold(new_threshold);
    assert(multisig.get_threshold() == new_threshold, 'threshold was not updated');
}

// test set_threshold with recursive call
#[test]
fn test_recursive_set_threshold() {
    // Defines helper variables
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let signers = array![s1, s2];
    let init_threshold: usize = 2;
    let new_threshold: usize = 1;

    // Deploys the contract
    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    // Gets a dispatcher (so we can call methods on the deployed contract)
    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    // Checks that the threshold was correctly initialized on deployment
    assert(multisig.get_threshold() == init_threshold, 'invalid init threshold');
    // Recursive call occurs here - this code proposes a transaction to the 
    // multisig contract that calls the set_threshold function on the multisig 
    // contract. 
    let mut set_threshold_calldata = ArrayTrait::new();
    Serde::serialize(@new_threshold, ref set_threshold_calldata);
    start_cheat_caller_address_global(s1);
    multisig
        .submit_transaction(multisig_address, selector!("set_threshold"), set_threshold_calldata);
    // Signer 1 confirms the transaction
    start_cheat_caller_address_global(s1);
    multisig.confirm_transaction(0);

    // Signer 2 confirms the transaction
    start_cheat_caller_address_global(s2);
    multisig.confirm_transaction(0);

    // Once we have enough confirmations, we execute the transaction
    // cheat only once because we want the multisig to execute the recursive tx
    cheat_caller_address(multisig_address, s1, CheatSpan::TargetCalls(1));

    multisig.execute_transaction(0);

    // Now we check that the threshold was actually updated
    assert(multisig.get_threshold() == new_threshold, 'threshold was not updated');
}

// test set_signers (non-recursive)
#[test]
fn test_set_signers() {
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let init_signers = array![s1, s2];
    let new_signers = array![s1];
    let threshold: usize = 2;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@init_signers, ref deploy_calldata);
    Serde::serialize(@threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    let returned_signers = multisig.get_signers();
    assert(returned_signers.len() == 2, 'should match signers length');
    assert(*returned_signers.at(0) == s1, 'should match signer 1');
    assert(*returned_signers.at(1) == s2, 'should match signer 2');
    assert(multisig.get_threshold() == 2, 'wrong init threshold');

    start_cheat_caller_address_global(multisig_address);
    multisig.set_signers(new_signers);

    let updated_signers = multisig.get_signers();
    assert(updated_signers.len() == 1, 'should match signers length');
    assert(*updated_signers.at(0) == s1, 'should match signer 1');
    assert(multisig.get_threshold() == 1, 'threshold not updated');
}

// test set_signers with recursive call
#[test]
fn test_recursive_set_signers() {
    // Defines helper variables
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let init_signers = array![s1, s2];
    let new_signers = array![s1];
    let init_threshold: usize = 2;

    // Deploys the contract
    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@init_signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    // Gets a dispatcher (so we can call methods on the deployed contract)
    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    // Checks that the signers were correctly initialized on deployment
    let returned_signers = multisig.get_signers();
    assert(returned_signers.len() == 2, 'should match signers length');
    assert(*returned_signers.at(0) == s1, 'should match signer 1');
    assert(*returned_signers.at(1) == s2, 'should match signer 2');
    assert(multisig.get_threshold() == 2, 'wrong init threshold');

    // Recursive call occurs here - this code proposes a transaction to the 
    // multisig contract that calls the set_signers function on the multisig 
    // contract. 
    let mut set_signers_calldata = ArrayTrait::new();
    Serde::serialize(@new_signers, ref set_signers_calldata);
    start_cheat_caller_address_global(s1);
    multisig.submit_transaction(multisig_address, selector!("set_signers"), set_signers_calldata);

    // Signer 1 confirms the transaction
    start_cheat_caller_address_global(s1);
    multisig.confirm_transaction(0);

    // Signer 2 confirms the transaction
    start_cheat_caller_address_global(s2);
    multisig.confirm_transaction(0);

    // Once we have enough confirmations, we execute the transaction
    cheat_caller_address(multisig_address, s1, CheatSpan::TargetCalls(1));
    multisig.execute_transaction(0);

    // Now we check that the signers were actually updated
    let updated_signers = multisig.get_signers();
    assert(updated_signers.len() == 1, 'should match signers length');
    assert(*updated_signers.at(0) == s1, 'should match signer 1');
    assert(multisig.get_threshold() == 1, 'wrong threshold');
}

// test set_signers_and_threshold (non-recursive)
#[test]
fn test_set_signers_and_threshold() {
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let s3 = contract_address_const::<3>();
    let init_signers = array![s1, s2, s3];
    let new_signers = array![s1, s2];
    let init_threshold: usize = 3;
    let new_threshold: usize = 1;

    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@init_signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    let returned_signers = multisig.get_signers();
    assert(returned_signers.len() == 3, 'should match signers length');
    assert(*returned_signers.at(0) == s1, 'should match signer 1');
    assert(*returned_signers.at(1) == s2, 'should match signer 2');
    assert(*returned_signers.at(2) == s3, 'should match signer 3');
    assert(multisig.get_threshold() == init_threshold, 'wrong init threshold');

    start_cheat_caller_address_global(multisig_address);
    multisig.set_signers_and_threshold(new_signers, new_threshold);

    let updated_signers = multisig.get_signers();
    assert(updated_signers.len() == 2, 'should match signers length');
    assert(*updated_signers.at(0) == s1, 'should match signer 1');
    assert(*updated_signers.at(1) == s2, 'should match signer 2');
    assert(multisig.get_threshold() == new_threshold, 'threshold not updated');
}

// test set_signers_and_threshold with recursive call
#[test]
fn test_recursive_set_signers_and_threshold() {
    // Defines helper variables
    let s1 = contract_address_const::<1>();
    let s2 = contract_address_const::<2>();
    let s3 = contract_address_const::<3>();
    let init_signers = array![s1, s2, s3];
    let new_signers = array![s1, s2];
    let init_threshold: usize = 3;
    let new_threshold: usize = 1;

    // Deploys the contract
    let mut deploy_calldata = ArrayTrait::new();
    Serde::serialize(@init_signers, ref deploy_calldata);
    Serde::serialize(@init_threshold, ref deploy_calldata);

    let (multisig_address, _) = declare("Multisig").unwrap().deploy(@deploy_calldata).unwrap();

    // Gets a dispatcher (so we can call methods on the deployed contract)
    let multisig = IMultisigDispatcher { contract_address: multisig_address };

    // Checks that the initial state is correct
    let returned_signers = multisig.get_signers();
    assert(returned_signers.len() == 3, 'should match signers length');
    assert(*returned_signers.at(0) == s1, 'should match signer 1');
    assert(*returned_signers.at(1) == s2, 'should match signer 2');
    assert(*returned_signers.at(2) == s3, 'should match signer 3');
    assert(multisig.get_threshold() == 3, 'wrong init threshold');

    // Recursive call occurs here - this code proposes a transaction to the 
    // multisig contract that calls the set_signers_and_threshold function 
    // on the multisig contract.
    let mut set_signers_and_threshold_calldata = ArrayTrait::new();
    Serde::serialize(@new_signers, ref set_signers_and_threshold_calldata);
    Serde::serialize(@new_threshold, ref set_signers_and_threshold_calldata);
    start_cheat_caller_address_global(s1);
    multisig
        .submit_transaction(
            multisig_address,
            selector!("set_signers_and_threshold"),
            set_signers_and_threshold_calldata
        );

    // Signer 1 confirms the transaction
    start_cheat_caller_address_global(s1);
    multisig.confirm_transaction(0);

    // Signer 2 confirms the transaction
    start_cheat_caller_address_global(s2);
    multisig.confirm_transaction(0);

    // Signer 3 confirms the transaction
    start_cheat_caller_address_global(s3);
    multisig.confirm_transaction(0);

    // Once we have enough confirmations, we execute the transaction
    cheat_caller_address(multisig_address, s1, CheatSpan::TargetCalls(1));
    multisig.execute_transaction(0);

    // Now we check that the signers were actually updated
    let updated_signers = multisig.get_signers();
    assert(updated_signers.len() == 2, 'should match signers length');
    assert(*updated_signers.at(0) == s1, 'should match signer 1');
    assert(*updated_signers.at(1) == s2, 'should match signer 2');
    assert(multisig.get_threshold() == 1, 'wrong threshold');
}

