program zkworkshopcankat_123.aleo {

    mapping account: address => u64;

    record token {
        owner: address,
        amount: u64
    }

    async transition mint_public(public receiver: address, public amount: u64) -> Future {
        return finalize_mint_public(receiver, amount);
    }

    async function finalize_mint_public(public receiver: address, public amount: u64) {
        let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, current_amount + amount);
    }

    transition mint_private(receiver: address, amount: u64) -> token {
        return token {
            owner: receiver,
            amount: amount
        };
    }

    async transition transfer_public(public receiver: address, public amount: u64) -> Future {
        return update_public_transfer(self.caller, receiver, amount);
    }

    async function update_public_transfer(public sender: address, public receiver: address, public amount: u64) {
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        if (sender_amount < amount) {
            revert("Insufficient funds");
        }
        Mapping::set(account, sender, sender_amount - amount);

        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    transition transfer_private(sender: token, receiver: address, amount: u64) -> (token, token) {
        if (sender.amount < amount) {
            revert("Insufficient funds");
        }

        let remaining: token = token {
            owner: sender.owner,
            amount: sender.amount - amount,
        };

        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        return (remaining, transferred);
    }

    async transition transfer_private_to_public(sender: token, public receiver: address, public amount: u64) -> (token, Future) {
        if (sender.amount < amount) {
            revert("Insufficient funds");
        }

        let remaining: token = token {
            owner: sender.owner,
            amount: sender.amount - amount,
        };

        return (remaining, finalize_private_to_public(receiver, amount));
    }

    async function finalize_private_to_public(public receiver: address, public amount: u64) {
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    async transition transfer_public_to_private(receiver: address, public amount: u64) -> (token, Future) {
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        return (transferred, finalize_transfer_public_to_private(self.caller, amount));
    }

    async function finalize_transfer_public_to_private(public sender: address, public amount: u64) {
        let current_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        if (current_amount < amount) {
            revert("Insufficient funds");
        }
        Mapping::set(account, sender, current_amount - amount);
    }

}
