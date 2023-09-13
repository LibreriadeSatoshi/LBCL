# Problem Statement

Timelocks are mechanisms to create transactions that are locked until X unit of time. These transactions cannot be included in the block until the said time has passed. This can be useful for various types of transaction workflow situations where funds are locked trustlessly.

OP_RETURN is an OP code that can be used to etch random data into a transaction. This has various use, from timestamping to Bitcoin-based NFTs.

In the following exercise, we go through a workflow where an `Employee` is getting paid by an `Employer` but only after a certain time has passed. The employee also exclaims in joy and post a OP_RETURN spend for the whole world to see that he isn't jobless anymore.


### Write a bash script to:

#### Setup a TimeLock contract

1. Create three wallets: `Miner`, `Employee`, and `Employer`.
2. Fund the wallets by generating some blocks for `Miner` and sending some coins to `Employer`.
3. Create a salary transaction of 40 BTC, where the `Employer` pays the `Employee`.
4. Add an absolute timelock of 500 Blocks for the transaction, i.e. the transaction cannot be included in the blockchain until the 500th block is mined.
5. Report in a comment what happens when you try to broadcast this transaction.
6. Mine up to 500th block and broadcast the transaction.
7. Print the final balances of `Employee` and `Employer`.

#### Spend from the TimeLock

1. Create a spending transaction where the `Employee` spends the fund to a new `Employee` wallet address.
2. Add an OP_RETURN output in the spending transaction with the string data "I got my salary, I am rich".
3. Extract and broadcast the fully signed transaction.
4. Print the final balances of the `Employee` and `Employer`.

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
 - Creating pull request via web browser: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
