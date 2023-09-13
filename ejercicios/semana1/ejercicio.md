# Problem Statement

The starting steps of any automated node software (Umbrel, MyNode, Raspibltiz etc) is to download the bitcoin binaries, verify signatures, install them in correct locations, provide specific user access, and then start the node.

The node will then go into IBD (Initial Block Download) phase, where it will download and validate the whole Bitcoin blockchain. Once the IBD completes, it will initiate a wallet and then the user can start transacting Bitcoin with the node (via node UI, or connecting mobile wallets to the node).

The following exercise is the toy version of the same process via bash script.

We will not have to do IBD, because we will be using `regtest` where we can create our own toy blocks with toy transactions.

### Write a bash script to:
 **-- Setup**
 - Download Bitcoin core binaries from Bitcoin Core Org https://bitcoincore.org/.
 - Use the downloaded hashes and signature to verify that binary is right. Print a message to terminal "Binary signature verification successful".
 - Copy the downloaded binaries to `/usr/local/bin/` for folder.

 **-- Initiate**
 - Create a `bitcoin.conf` file in the `/home/<user-name>/.bitcoin/` data directory. Create the directory if it doesn't exist. And add the following lines to the file.
  ```
    regtest=1
    fallbackfee=0.0001
    server=1
    txindex=1
  ```
  - start `bitcoind`.
  - create two wallet named `Miner` and `Trader`.
  - Generate one address from the `Miner` wallet with a label "Mining Reward".
  - Mine new blocks to this address until you get positive wallet balance. (use `generatetoaddress`) (how many blocks it took to get to positive balance)
  - Write a short comment describing why wallet balance for block rewards behaves that way.
  - Print the balance of the `Miner` wallet.

  **-- Usage**
  - Create a receiving addressed labeled "Received" from `Trader` wallet.
  - Send a transaction paying 20 BTC from `Miner` wallet to `Trader`'s wallet.
  - Fetch the unconfirmed transaction from the node's mempool and print the result. (hint: `bitcoin-cli help` to find list of all commands, look for `getmempoolentry`).
  - Confirm the transaction by creating 1 more block.
  - Fetch the following details of the transaction and print them into terminal.
    - `txid`: `<transaction id>`
    - `<From, Amount>`: `<Miner's address>, Input Amount`.
    - `<Send, Amount>`: `<Trader's address>, Sent Amount`,
    - `<Change, Amount>`: `<Miner's address>, Change Back amount`.
    - `Fees`: `Amount paid in fees`.
    - `Block: Block height at which the transaction is confirmed`.
    - `Miner Balance`: `Balance of the Miner wallet after transsaction`
    - `Trader Balance`: `Balance of the Trader wallet after transaction`

# Hints

- To download the latest binaries for linux x86-64, via command line: `wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz`
- Search up in google for terminal commands for a specific task, if you don't have them handy. Ex: "how to extract a zip folder via linux terminal", "how to copy files into another directory via linux terminal", etc.
- Use `jq` tool to fetch specific data from `json` objects returned by `bitcoin-cli`.

# Submission

 - This week's solution folder is here: [solution folder](/ejercicios/semana1/soluciones/).
 - Create a pull request to add a new file to the folder named `<your-discord-name>.sh`.
 - This file should contain your working bash script of the whole exercise.
 - The exercise steps are mandatory to be reflected, but feel free to add your own scripting perks. 


# Resources

 - Useful bash script examples: https://linuxhint.com/30_bash_script_examples/
 - More on Initial Block Download: https://bitcoin.org/en/full-node#initial-block-downloadibd
 - Useful `jq` examples: https://www.baeldung.com/linux/jq-command-json
 - Creating pull request via web browser: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
