# Problem Statement

Multisig transactions are a fundamental aspect of "complex Bitcoin scripting," enabling co-ownership of Bitcoin UTXOs. They play a crucial role in co-custody solutions for Layer 2 (L2) protocols.

L2 protocols commonly initiate by establishing a multisig funding transaction among involved parties. For instance, in Lightning, both parties may co-fund the transaction before conducting their lightning transactions. Upon closing the channel, they can settle the multisig to reclaim their respective shares.

In this exercise, we aim to simulate a basic multisig share transfer between two participants, Alice and Bob.

### Write a bash script to:

#### Setup Multisig

1. Create three wallets: `Miner`, `Alice`, and `Bob`.
2. Fund the wallets by generating some blocks for `Miner` and sending some coins to `Alice` and `Bob`.
3. Create a 2-of-2 Multisig address by combining public keys from `Alice` and `Bob`.
4. Create a Partially Signed Bitcoin Transaction (PSBT) to fund the multisig address with 20 BTC, taking 10 BTC each from `Alice` and `Bob`, and providing correct change back to each of them.
5. Confirm the balance by mining a few more blocks.
6. Print the final balances of `Alice` and `Bob`.

#### Settle Multisig

1. Create a PSBT to spend funds from the multisig, ensuring 10 BTC is equally distributed back between `Alice` and `Bob` after accounting for fees.
2. Sign the PSBT by `Alice`.
3. Sign the PSBT by `Bob`.
4. Extract and broadcast the fully signed transaction.
5. Print the final balances of `Alice` and `Bob`.

## Submission

- Create a bash script with your solution for the entire exercise.
- Save the script in the provided solution folder with the name `<your-discord-name>.sh`.
- Create a pull request to add the new file to the solution folder.
- The script must include all the exercise steps, but you can also add your own scripting improvements or enhancements.

## Resources

- Useful bash script examples: [https://linuxhint.com/30_bash_script_examples/](https://linuxhint.com/30_bash_script_examples/)
- Useful `jq` examples: [https://www.baeldung.com/linux/jq-command-json](https://www.baeldung.com/linux/jq-command-json)
- Use `jq` to create JSON: [https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/](https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/)
- Creating a pull request via a web browser: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)


# Resources

 - Useful bash script examples: https://linuxhint.com/30_bash_script_examples/
 - More on Initial Block Download: https://bitcoin.org/en/full-node#initial-block-downloadibd
 - Useful `jq` examples: https://www.baeldung.com/linux/jq-command-json
 - Createing pull request via web browser: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
