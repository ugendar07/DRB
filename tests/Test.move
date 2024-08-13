#[test_only]
module address::RandomnessBeaconTests {
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use address::RandomnessBeacon;

    // Test account addresses
    const ADMIN: address = @0xABCD;
    const USER1: address = @0x1234;
    const USER2: address = @0x5678;

    // Test helper function to create and fund an account
    fun create_test_account(framework: &signer, addr: address): signer {
        let new_account = account::create_account_for_test(addr);
        coin::register<AptosCoin>(&new_account);
        let amount:u64 = 1000000000;
        coin::deposit(
            signer::address_of(&new_account),
            coin::mint<AptosCoin>(framework, amount)
        );
        new_account
    }

    #[test(framework = @aptos_framework)]
    public fun test_initialize(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);
        // Add assertions here to check if the initialization was successful
    }

    #[test(framework = @aptos_framework)]
    public fun test_commit(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);

        let user1 = create_test_account(framework, USER1);
        let data_hash = x"1234567890ABCDEF";
        let amount = 1000000; // This should match the fixed_amount in the contract

        RandomnessBeacon::commit(&user1, data_hash, amount);
        // Add assertions here to check if the commit was successful
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(abort_code = 100)] // E_INVALID_AMOUNT
    public fun test_commit_invalid_amount(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);

        let user1 = create_test_account(framework, USER1);
        let data_hash = x"1234567890ABCDEF";
        let invalid_amount = 500000; // This is not the correct fixed_amount

        RandomnessBeacon::commit(&user1, data_hash, invalid_amount);
    }

    #[test(framework = @aptos_framework)]
    public fun test_reveal(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);

        let user1 = create_test_account(framework, USER1);
        let data_hash = x"1234567890ABCDEF";
        let amount = 1000000;
        RandomnessBeacon::commit(&user1, data_hash, amount);

        let answer = x"FEDCBA0987654321";
        let salt = x"0123456789ABCDEF";
        RandomnessBeacon::reveal(&user1, answer, salt);
        // Add assertions here to check if the reveal was successful
    }

    #[test(framework = @aptos_framework)]
    #[expected_failure(abort_code = 101)] // E_ALREADY_REVEALED
    public fun test_double_reveal(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);

        let user1 = create_test_account(framework, USER1);
        let data_hash = x"1234567890ABCDEF";
        let amount = 1000000;
        RandomnessBeacon::commit(&user1, data_hash, amount);

        let answer = x"FEDCBA0987654321";
        let salt = x"0123456789ABCDEF";
        RandomnessBeacon::reveal(&user1, answer, salt);
        // This second reveal should fail
        RandomnessBeacon::reveal(&user1, answer, salt);
    }

    #[test(framework = @aptos_framework)]
    public fun test_multiple_commits_and_reveals(framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        let admin = create_test_account(framework, ADMIN);
        RandomnessBeacon::initialize(&admin);

        let user1 = create_test_account(framework, USER1);
        let user2 = create_test_account(framework, USER2);
        let amount = 1000000;

        RandomnessBeacon::commit(&user1, x"1111111111111111", amount);
        RandomnessBeacon::commit(&user2, x"2222222222222222", amount);

        RandomnessBeacon::reveal(&user1, x"AAAAAAAAAAAAAAAA", x"1111111111111111");
        RandomnessBeacon::reveal(&user2, x"BBBBBBBBBBBBBBBB", x"2222222222222222");

        // Add assertions here to check if both commits and reveals were successful
    }
}