# LBTCL Cohort Exercise Week 2

## Problem Statement
Now that we have a running Bitcoin node, with a wallet connected, in this exercise, we will perform some basic Bitcoin wallet usage workflows using bash scripting and the `bitcoin-cli` command-line interface. We will focus on fee bumping using Replace-By-Fee (RBF) and Child-Pays-for-Parent (CPFP) mechanisms.

Wallets often need to fee-bump transactions in times of high fee-rate markets. There are two ways of fee bumping, RBF and CPFP. They both use different mechanisms for bumping the fee, but they cannot be used together. Trying to RBF a transaction would invalidate the CPFP, because the child transaction cannot be valid if its parent is removed from the mempool.

The following exercise attempts to demo that situation.

## Task

Write a bash script to:

1. Create two wallets named `Miner` and `Trader`.
2. Fund the `Miner` wallet with at least 3 block rewards worth of satoshis (Starting balance: 150 BTC).
3. Craft a transaction from `Miner` to `Trader` with the following structure (let's call it the `Parent` transaction):
   - Input[0]: 50 BTC block reward.
   - Input[1]: 50 BTC block reward.
   - Output[0]: 70 BTC to `Trader`.
   - Output[1]: 29.99999 BTC change-back to `Miner`.
   - **Signal for RBF** (Enable RBF for the transaction).
4. Sign and broadcast the `Parent` transaction but do not mine it yet.
5. Make queries to the node's mempool to get the `Parent` transaction details. Use the details to craft a JSON variable with the following structure:

```json
{
  "input": [
	{
  	"txid": "<Trader's Txid>",
  	"vout": "<num>"
	},
	{
  	"txid": "<Miner's Txid>",
  	"vout": "<num>"
	}
  ],
  "output": [
	{
  	"script_pubkey": "<Miner's script_pubkey>",
  	"amount": "<miner's amount>"
	},
	{
  	"script_pubkey": "<Trader's script pubkey>",
  	"amount": "<trader's amount>"
	}
  ],
  "Fees": "<num>",
  "Weight": "<num>" (weight of the tx in vbytes)
}
```

- Use `bitcoin-cli help` to get all the category-specific commands (wallet, mempool, chain, etc.).
- Use `bitcoin-cli help <command-name>` to get usage information of specific commands.
- Use `jq` to fetch data from `bitcoin-cli` output into bash variables and use `jq` again to craft your JSON from the variables.
- You might have to make multiple CLI calls to get all the details.

6. Print the above JSON in the terminal.
7. Create a broadcast new transaction that spends from the above transaction (the `Parent`). Let's call it the `Child` transaction.
   - Input[0]: `Miner`'s output of the `Parent` transaction.
   - Output[0]: `Miner`'s new address. 29.99998 BTC.
8. Make a `getmempoolentry` query for the `Child` transaction and print the output.

9. Now, fee bump the `Parent` transaction using RBF. Do not use `bitcoin-cli bumpfee`, instead hand-craft a conflicting transaction, that has the same inputs as the `Parent` but different outputs, adjusting their values to bump the fee of `Parent` by 10,000 satoshis.
10. Sign and broadcast the The new Parent transaction.
11. Make another `getmempoolentry` query for the `Child` transaction and print the result.
12. Print an explanation in the terminal of what changed in the two `getmempoolentry` results for the `Child` transactions, and why?

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
