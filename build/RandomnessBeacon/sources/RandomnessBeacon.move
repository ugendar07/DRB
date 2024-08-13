module address::RandomnessBeacon {
    use std::signer;
    use aptos_framework::event::{Self};
    use aptos_framework::timestamp;
    use std::vector;
    use aptos_std::table::{Self, Table};

    // Existing struct definitions remain the same
    struct Commit has copy, drop, store {
        sender: address,
        commit: vector<u8>,
        block_number: u64,
        revealed: bool
    }

    struct Reveal has copy, drop, store {
        sender: address,
        block_number: u64,
        answer: vector<u8>,
        salt2: vector<u8>
    }

    #[event]
    struct CommitHashEvent has copy, drop, store {
        sender: address,
        data_hash: vector<u8>,
        block_number: u64
    }

    #[event]
    struct RevealedHashEvent has copy, drop, store {
        revealed_hash: vector<Reveal>
    }

    #[event]
    struct RandomNumberEvent has copy, drop, store {
        rand_number: u64
    }

    struct RandomnessBeaconStorage has key {
        rand_number: vector<u8>,
        fixed_amount: u64,
        required_parties: u64,
        revealed_parties: u64,
        revealed_hash: vector<vector<u8>>,
        commit_history: vector<Commit>,
        reveal_history: vector<Reveal>,
        commits: Table<address, Commit>
    }

    // Error constants
    const E_INVALID_AMOUNT: u64 = 100;
    const E_ALREADY_REVEALED: u64 = 101;

    public fun initialize(account: &signer) {
        let beacon = RandomnessBeaconStorage {
            rand_number: vector::empty(),
            fixed_amount: 1000000,
            required_parties: 3,
            revealed_parties: 0,
            revealed_hash: vector::empty(),
            commit_history: vector::empty(),
            reveal_history: vector::empty(),
            commits: table::new()
        };
        move_to(account, beacon);
    }

    public fun commit(account: &signer, data_hash: vector<u8>, amount: u64) acquires RandomnessBeaconStorage {
        let sender = signer::address_of(account);
        let beacon = borrow_global_mut<RandomnessBeaconStorage>(sender);
        
        assert!(amount == beacon.fixed_amount, E_INVALID_AMOUNT);

        let block_number = timestamp::now_microseconds();

        let new_commit = Commit {
            sender,
            commit: data_hash,
            block_number,
            revealed: false
        };

        if (table::contains(&beacon.commits, sender)) {
            let old_commit = table::remove(&mut beacon.commits, sender);
            if (!old_commit.revealed) {
                clear_commit_history(&mut beacon.commit_history, sender);
            };
        };

        table::add(&mut beacon.commits, sender, new_commit);
        vector::push_back(&mut beacon.commit_history, new_commit);

        event::emit(CommitHashEvent { 
            sender, 
            data_hash, 
            block_number 
        });
    }

    public fun reveal(account: &signer, answer: vector<u8>, salt: vector<u8>) acquires RandomnessBeaconStorage {
        let sender = signer::address_of(account);
        let beacon = borrow_global_mut<RandomnessBeaconStorage>(sender);
        
        assert!(table::contains(&beacon.commits, sender), E_ALREADY_REVEALED);
        let commit = table::borrow_mut(&mut beacon.commits, sender);
        assert!(!commit.revealed, E_ALREADY_REVEALED);

        // Reveal logic here...
        commit.revealed = true;
        beacon.revealed_parties = beacon.revealed_parties + 1;

        let reveal = Reveal {
            sender,
            block_number: timestamp::now_microseconds(),
            answer,
            salt2: salt
        };
        vector::push_back(&mut beacon.reveal_history, reveal);

        // Check if all required parties have revealed
        if (beacon.revealed_parties == beacon.required_parties) {
            emit_final_random_number(beacon);
            beacon.rand_number = vector::empty(); // Reset the random number
        }
    }

    fun emit_final_random_number(beacon: &mut RandomnessBeaconStorage) {
        let rand_number = vector::pop_back(&mut beacon.rand_number);
        let final_number = (rand_number as u64) % 100 + 1;
        event::emit(RandomNumberEvent { rand_number: final_number });
    }

    fun clear_commit_history(commit_history: &mut vector<Commit>, sender: address) {
        let i = 0;
        while (i < vector::length(commit_history)) {
            if (vector::borrow(commit_history, i).sender == sender) {
                vector::remove(commit_history, i);
            };
            i = i + 1;
        };
    }
}