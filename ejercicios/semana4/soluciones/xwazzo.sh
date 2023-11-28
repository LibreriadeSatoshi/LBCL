RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"
NODE_VERSION="25.1"

section_flag() {
    echo -e "${RED}================================================================${ENDCOLOR}"
    echo -e "${BLUE} >>             $1             << ${ENDCOLOR}"
    echo -e "${RED}================================================================${ENDCOLOR}"
}

info_flag() {
    echo -e "\n${YELLOW} $1 ${ENDCOLOR}"
}

success_flag() {
    echo -e "\n${GREEN} ✅ $1 ${ENDCOLOR}"
}

error_flag() {
    echo -e "\n${RED} ❌ ERROR: ${ENDCOLOR} $1"
}

download_node() {
    section_flag "Downloading Bitcoin node (bitcoin-${NODE_VERSION})"
    wget https://bitcoincore.org/bin/bitcoin-core-${NODE_VERSION}/bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz
    wget https://bitcoincore.org/bin/bitcoin-core-${NODE_VERSION}/SHA256SUMS
    wget https://bitcoincore.org/bin/bitcoin-core-${NODE_VERSION}/SHA256SUMS.asc

    verify_signatures
}

verify_signatures() {
    section_flag "About to verify signatures"

    info_flag "check SHA256SUMS"
    sha256sum --ignore-missing --check SHA256SUMS

    info_flag "download signatures"
    git clone https://github.com/bitcoin-core/guix.sigs

    info_flag "import signatures"
    gpg --import guix.sigs/builder-keys/*

    info_flag "verify SHA256SUMS.asc"
    gpg --verify SHA256SUMS.asc
}

remove_tar_and_move_bins() {
    section_flag "Removing tar and move bins"

    # if [[ -f "bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz" ]]; then
        info_flag "open tar.gz"
        tar -xvf bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz
        info_flag "remove tar.gz"
        rm -rf bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz

        info_flag "move bins to /usr/local/bin"
        mv $HOME/bitcoin-${NODE_VERSION}/bin/* /usr/local/bin/

        info_flag "remove bitcoin-${NODE_VERSION} folder"
        rm -rf bitcoin-${NODE_VERSION}
    # else
    #     error_flag "NOT FOUND - bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz"
    # fi
}

create_alias() {
    info_flag "creating bitcoind and bitcoin-cli alias"
    # Bitcoin Alias

    cat <<EOF >>$HOME/.bashrc
    alias bitcoind="/usr/local/bin/bitcoind"
    alias bitcoin-cli="/usr/local/bin/bitcoin-cli"
EOF

    info_flag "propagate alias update"
    . "$HOME/.bashrc"
}

configurate_node() {
    section_flag "Configurate Node"
    info_flag "creating bitcoin folder"
    mkdir -m 755 $HOME/.bitcoin

    cat <<EOF >$HOME/.bitcoin/bitcoin.conf
        regtest=1
        fallbackfee=0.00001
        server=1
        txindex=1
        mempoolfullrbf=1
        listenonion=0

        [regtest]
        rpcuser=test
        rpcpassword=test321
        rpcbind=0.0.0.0
        rpcallowip=0.0.0.0/0
        zmqpubrawblock=tcp://0.0.0.0:28332
        zmqpubrawtx=tcp://0.0.0.0:28332
        zmqpubhashtx=tcp://0.0.0.0:28332
        zmqpubhashblock=tcp://0.0.0.0:28332
EOF

    info_flag "updating chmod to bitcoin.conf file to 400 for security reasons"
    chmod 400 .bitcoin/bitcoin.conf
}

clean_files() {
    info_flag "Remove all files and folders created";

    if compgen -G "$HOME/SHA256SUMS*" > /dev/null; then
        rm SHA256SUMS*
        success_flag "SHASHA256SUMS removed";
    else
        error_flag "NOT FOUND - $HOME/SHA256SUMS*"
    fi

    if compgen -G "/usr/local/bin/bitcoin*" > /dev/null; then
        rm -rf /usr/local/bin/bitcoin*
        rm /usr/local/bin/test_bitcoin
        success_flag "bitcoin bins removed";
    else
        echo "NOT FOUND - /usr/local/bin/bitcoin*"
    fi

    if [[ -d "$HOME/.bitcoin" ]]; then
        rm -rf .bitcoin
        success_flag ".bitcoin folder removed";
    else
        error_flag "NOT FOUND - $HOME/.bitcoin"
    fi
}

start_node() {
    section_flag "Starting node as background process"
    bitcoind -printtoconsole -debug=1 -debugexclude=http -debugexclude=rpc > /proc/1/fd/1 2>&1 &
}

#1 - wallet_name ex. "Miner"
# output - json with name ex. {"name": "Test"}
create_wallet() {
    bitcoin-cli -named createwallet wallet_name=$1 descriptors=false
}

# $1 - wallet_name ex. "Miner"
# $2 - label ex. "Mining Rewards"
# output - address
create_new_address() {
    bitcoin-cli -rpcwallet=$1 getnewaddress "$2"
}

# $1 - wallet_name ex. "Miner"
# $2 - public_key ex. bcrt1qqjvcvmpwke5pdchtzfd2p7degtmjj4x3dtvq05
# output - pubkey
get_address_public_key() {
    bitcoin-cli -regtest -rpcwallet=$1 -named getaddressinfo address=$2 | jq -r '.pubkey'
}

# $1 - label ex. "Miner"
# $2 - label ex. "Mining Reward"
# output - address
# get_address_by_label "Miner" "Mining Reward"
get_address_by_label() {
    bitcoin-cli -rpcwallet="$1" getaddressesbylabel "$2" | jq -r 'keys[0]'

    # bitcoin-cli -rpcwallet="$1" listreceivedbyaddress | jq -r --arg lbl "$2" '.[] | select(.label == $lbl) | .address'
}

# $1 - wallet_name ex. "Miner"
get_wallet_balance() {
    bitcoin-cli -rpcwallet="$1" getwalletinfo | jq ".balance"
}

# Automatic Processes
# ===========================

install_dependencies() {
    section_flag "About to install dependencies"

    apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
}

install_node() {
    download_node
    sleep 10
    ls -la "bitcoin-${NODE_VERSION}-x86_64-linux-gnu.tar.gz"
    remove_tar_and_move_bins
    sleep 2
    create_alias
    sleep 2
    configurate_node
}

# $1 - wallet_name ex. "Miner"
# $2 - wallet_name ex. "Mining Reward"
# create_wallet_and_mine_to_address "Miner" "Mining Reward"
create_wallet_and_mine_to_address() {
    bitcoin-cli -named createwallet wallet_name=$1 descriptors=true

    success_flag "$1 wallet created"
    ADDRESS=$(create_new_address $1 "$2")
    success_flag "created address on wallet $1 label $2"
    info_flag "address: $ADDRESS" 

    info_flag "get pubkey on wallet $1 address $ADDRESS"
    PUB_KEY=$(get_address_public_key $1 $ADDRESS)
    info_flag $PUB_KEY

    mine_to_address_until_more_than_x $1 $ADDRESS 99
}

# $1 - wallet_name ex. "Miner"
# $2 - public_key ex. "bcrt1qqjvcvmpwke5pdchtzfd2p7degtmjj4x3dtvq05"
# $3 - more than ex. 0
mine_to_address_until_more_than_x() {
    BALANCE=$(get_wallet_balance "$1")
    info_flag "Initial balance: $BALANCE"
    BLOCK_COUNT=0

    info_flag "About to start mining blocks until we have more than $3 due to mining reward"
    while [ $BALANCE -le $3 ]; do
        # info_flag "Mining to address. Current block count: $BLOCK_COUNT"
        bitcoin-cli -rpcwallet="$1" generatetoaddress 1 "$2"

        BALANCE=$(get_wallet_balance "$1")
        # info_flag "New balance $BALANCE"

        BLOCK_COUNT=$((BLOCK_COUNT + 1))
        # info_flag "Block count is $BLOCK_COUNT"
    done

    success_flag "We have mined $BLOCK_COUNT blocks and the balance is $BALANCE"
}

# Uso - exercise 
# ===========================
# $1 - reciever wallet_name ex. "Trader"
# $2 - reciever address label ex. "Recibido"
# $3 - sender wallet_name ex. "Miner"
# $4 - sender address label ex. "Mining Reward"
# week_1 "Trader" "Recibido" "Miner" "Mining Reward"
week_1() {
    section_flag "xwazzo: Week 1 solution"
    SENT_BTC=20
    # Crear una dirección receptora con la etiqueta "Recibido" desde la billetera Trader.
    create_wallet "$1"
    success_flag "$1 wallet created"
    RECEPTOR_ADDRESS=$(create_new_address $1 "$2")
    success_flag "created address on wallet $1 label $2"
    info_flag "address: $RECEPTOR_ADDRESS" 

    info_flag "get pubkey on wallet $1 address $RECEPTOR_ADDRESS"
    PUB_KEY=$(get_address_public_key $1 $RECEPTOR_ADDRESS)
    info_flag $PUB_KEY

    SENDER_BALANCE=$(get_wallet_balance "$3")

    # Enviar una transacción que pague 20 BTC desde la billetera Miner a la billetera del Trader.
    TXID=$(bitcoin-cli -rpcwallet=$3 sendtoaddress $RECEPTOR_ADDRESS $SENT_BTC)
    success_flag "Sent $SENT_BTC BTC from $3 to Receptor Address $RECEPTOR_ADDRESS"
    info_flag "transaction id $TXID"

    # Obtener la transacción no confirmada desde el "mempool" del nodo y mostrar el resultado. (pista: bitcoin-cli help para encontrar la lista de todos los comandos, busca getmempoolentry).
    bitcoin-cli getmempoolentry $TXID
    success_flag "Get transaction from mempool"

    # Confirmar la transacción creando 1 bloque adicional.
    SENDER_ADDRESS=$(get_address_by_label "$3" "$4")
    bitcoin-cli -rpcwallet="$3" generatetoaddress 1 "$SENDER_ADDRESS"
    success_flag "confirm 1 transaction"

    # Obtener los siguientes detalles de la transacción y mostrarlos en la terminal:
    # txid: <ID de la transacción>
    # <De, Cantidad>: <Dirección del Miner>, Cantidad de entrada.
    # <Enviar, Cantidad>: <Dirección del Trader>, Cantidad enviada.
    # <Cambio, Cantidad>: <Dirección del Miner>, Cantidad de cambio.

    # Comisiones: Cantidad pagada en comisiones.
    # Bloque: Altura del bloque en el que se confirmó la transacción.
    # Saldo de Miner: Saldo de la billetera Miner después de la transacción.
    # Saldo de Trader: Saldo de la billetera Trader después de la transacción.

    success_flag "txid: $TXID"
    success_flag "<De, $SENDER_BALANCE>: $3 $SENDER_ADDRESS"
    success_flag "<Enviar, $SENT_BTC>: $1 $RECEPTOR_ADDRESS"

    FEE=$(bitcoin-cli -rpcwallet="$3" gettransaction $TXID | jq -r '.fee')

    RESULT=$(awk "BEGIN{ print ($SENDER_BALANCE - $SENT_BTC + $FEE) }")
    success_flag "<Cambio, $RESULT>"

    # Comisiones: Cantidad pagada en comisiones.
    success_flag "Comisiones: $FEE"

    BLOCK_HEIGHT=$(bitcoin-cli -rpcwallet="$1" gettransaction $TXID | jq -r '.blockheight')
    success_flag "Bloque: $BLOCK_HEIGHT"

    NEW_SENDER_BALANCE=$(get_wallet_balance "$3")
    success_flag "Saldo de Miner: $NEW_SENDER_BALANCE"

    NEW_RECEPTOR_BALANCE=$(get_wallet_balance "$1")
    success_flag "Saldo de Trader: $NEW_RECEPTOR_BALANCE"
}

# Crate raw change address
# $1 - wallet_name
create_raw_change_address() {
    WALLET_NAME=$1

    bitcoin-cli -rpcwallet="$WALLET_NAME" getrawchangeaddress
}

# Create, sign and send raw transaction
# $1 - wallet_name (string) ex. Miner
# $2 - inputs (JSON) ex. [{"txid": .txid, "vout": .vout, "sequence": 1}, {"txid": .txid, "vout": .vout, "sequence": 1}]
# $3 - outputs (JSON) ex. [{".address": .value}, {".address": .value}]
create_raw_sign_send_transaction() {
    WALLET_NAME=$1
    INPUTS=$2
    OUTPUTS=$3

    # info_flag "About to create raw transaction" 
    RAW_TRX=$(bitcoin-cli -named createrawtransaction inputs="$INPUTS" outputs="$OUTPUTS")
    # info_flag "RAW_TRX: $RAW_TRX"

    SIGNED_RAW_TRX=$(bitcoin-cli -rpcwallet="$WALLET_NAME" signrawtransactionwithwallet "$RAW_TRX")
    # info_flag "SIGNED_RAW_TRX: $SIGNED_RAW_TRX"

    RAW_TXID=$(bitcoin-cli sendrawtransaction $(echo $SIGNED_RAW_TRX | jq -r .hex))
    # info_flag "RAW_TXID: $RAW_TXID"

    DECODE_RAW_TRX=$(bitcoin-cli decoderawtransaction $RAW_TRX)
    # info_flag "DECODE_RAW_TRX: $DECODE_RAW_TRX"

    echo {\"raw_trx\": \"$RAW_TRX\", \"signed_raw_trx\": $SIGNED_RAW_TRX, \"raw_txid\": \"$RAW_TXID\", \"decode_raw_trx\": $DECODE_RAW_TRX}
}

# Uso - exercise 
# ===========================
# week_2
week_2() {
    TRADER="Trader"
    TRADER_PAYMENT="Trader Payment"
    MINER="Miner"
    SENT_BTC=70

    section_flag "xwazzo: Week 2 solution"

    create_wallet "$TRADER"
    success_flag "$TRADER wallet created"

    # Crear una dirección receptora con la etiqueta "TRADER_PAYMENT" desde la billetera Trader.
    TRADER_PAYMENT_ADDRESS=$(create_new_address $TRADER "$TRADER_PAYMENT")
    info_flag "$TRADER: address $TRADER_PAYMENT_ADDRESS" 
    success_flag "created address on wallet $TRADER label $TRADER_PAYMENT"

    # Crea una dirección raw para recibir el cambio
    MINER_CHANGE_ADDRESS=$(create_raw_change_address "$MINER")
    info_flag "$MINER: raw change address $MINER_CHANGE_ADDRESS"

    BLOCK_0=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')
    info_flag "Bloque 0: $BLOCK_0" 

    BLOCK_1=$(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[1] | {"txid": .txid, "vout": .vout, "sequence": 1}')
    info_flag "Bloque 1: $BLOCK_1" 

    MINER_CHANGE=29.99999
    
    info_flag "{\"inputs\": [$BLOCK_0, $BLOCK_1], \"outputs\": [{\"$TRADER_PAYMENT_ADDRESS\": $SENT_BTC}, {\"$MINER_CHANGE_ADDRESS\": $MINER_CHANGE}]}"

    PARENT_RAW_JSON=$(create_raw_sign_send_transaction "Miner" "[$BLOCK_0, $BLOCK_1]" "[{\"$TRADER_PAYMENT_ADDRESS\": $SENT_BTC}, {\"$MINER_CHANGE_ADDRESS\": $MINER_CHANGE}]")
    
    PARENT_TRX=$(echo $PARENT_RAW_JSON | jq -r .raw_trx)
    PARENT_TXID=$(echo $PARENT_RAW_JSON | jq -r .raw_txid)
    info_flag "PARENT_TRX: $PARENT_TRX"
    info_flag "PARENT_TXID: $PARENT_TXID"

    PARENT_RAW_TRX=$(bitcoin-cli decoderawtransaction $PARENT_TRX)
    info_flag "PARENT_RAW_TRX: $PARENT_RAW_TRX"

    INPUT_TRADER_RAW=$(echo $PARENT_RAW_TRX | jq -r '.vin[0] | {"txid": .txid, "vout": .vout}')
    INPUT_MINER_RAW=$(echo $PARENT_RAW_TRX | jq -r '.vin[1] | {"txid": .txid, "vout": .vout}')

    OUTPUT_TRADER_RAW=$(echo $PARENT_RAW_TRX | jq -r '{"script_pubkey":.vout[1].scriptPubKey, "amount":.vout[1].value}')
    OUTPUT_MINER_RAW=$(echo $PARENT_RAW_TRX | jq -r '{"script_pubkey":.vout[0].scriptPubKey, "amount":.vout[0].value}')

    MEMPOOL_PARENT_ENTRY=$(bitcoin-cli getmempoolentry $PARENT_TXID)

    PARENT_FEES=$(echo $MEMPOOL_PARENT_ENTRY | jq -r .fees.base)
    PARENT_WEIGHT=$(echo $MEMPOOL_PARENT_ENTRY | jq -r .weight)

    JSON_MEMPOOL="{ \"input\":[$INPUT_TRADER_RAW, $INPUT_MINER_RAW], \"output\": [$OUTPUT_TRADER_RAW, $OUTPUT_MINER_RAW], \"Fees\":$PARENT_FEES, \"Weight\": $PARENT_WEIGHT}"
    
    # 6. Imprime el JSON anterior en la terminal.
    echo $JSON_MEMPOOL | jq

    # 7. Crea una nueva transmisión que gaste la transacción anterior (parent). Llamémosla transacción child.
    MINER_NEW_CHANGE_ADDRESS=$(create_raw_change_address "$MINER")
    success_flag "New miner change address created"
    info_flag "MINER_NEW_CHANGE_ADDRESS: $MINER_NEW_CHANGE_ADDRESS"

    MINER_CHANGE_UPDATE=29.99998
    CHILD_RAW_JSON=$(create_raw_sign_send_transaction "Miner" "[{\"txid\":\"$PARENT_TXID\", \"vout\": 1}]" "[{\"$MINER_NEW_CHANGE_ADDRESS\": $MINER_CHANGE_UPDATE}]")

    CHILD_TRX=$(echo $CHILD_RAW_JSON | jq -r .raw_trx)
    CHILD_TXID=$(echo $CHILD_RAW_JSON | jq -r .raw_txid)
    info_flag "CHILD_TRX: $CHILD_TRX"
    info_flag "CHILD_TXID: $CHILD_TXID"

    CHILD_RAW_TRX=$(bitcoin-cli decoderawtransaction $CHILD_TRX)
    info_flag "CHILD_RAW_TRX: $CHILD_RAW_TRX"

    # 8. Realiza una consulta getmempoolentry para la tranasacción child y muestra la salida
    MEMPOOL_CHILD_ENTRY=$(bitcoin-cli getmempoolentry $CHILD_TXID)
    info_flag "MEMPOOL_CHILD_ENTRY: $MEMPOOL_CHILD_ENTRY"

    # bitcoin-cli getrawmempool | jq
    MINER_CHANGE_UPDATE=$(echo "$MINER_CHANGE_UPDATE - 0.00010000" | bc)
    info_flag "New MINER_CHANGE_UPDATE: $MINER_CHANGE_UPDATE"

    # 9. Ahora, aumenta la tarifa de la transacción parent utilizando RBF
    # 10. Firma y transmite la nueva transacción principal
    NEW_RAW_TRX=$(create_raw_sign_send_transaction "Miner" "[$BLOCK_0, $BLOCK_1]" "[{\"$TRADER_PAYMENT_ADDRESS\": $SENT_BTC}, {\"$MINER_CHANGE_ADDRESS\": $MINER_CHANGE_UPDATE}]")
    info_flag "NEW_RAW_TRX: $NEW_RAW_TRX"

    bitcoin-cli getrawmempool | jq

    # 11. Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado
    MEMPOOL_CHILD_ENTRY=$(bitcoin-cli getmempoolentry $CHILD_TXID)
    info_flag "MEMPOOL_CHILD_ENTRY UPDATED: $MEMPOOL_CHILD_ENTRY"

    # 12. Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry para las transacciones child y por qué
    info_flag "Marca error cuando buscamos la transacción child ya que al modificarla, se crea una nueva y deja de existir la anterior en la mempool"
}

week_3() {
    MINER="Miner"
    ALICE="Alice"
    BOB="Bob"
    MINER_ADDRESS=$(get_address_by_label "Miner" "Mining Reward")

    section_flag "xwazzo: Week 3 solution"

    # 1. Crear tres monederos: Miner, Alice y Bob
    info_flag "1. Crear tres monederos: Miner, Alice y Bob"
    create_wallet "$ALICE"
    success_flag "$ALICE wallet created"

    create_wallet "$BOB"
    success_flag "$BOB wallet created"

    # 2. Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob
    info_flag "2. Fondear los monederos generando algunos bloques para Miner y enviando algunas monedas a Alice y Bob"
    MINER_BALANCE=$(bitcoin-cli -rpcwallet=$MINER getbalance)
    success_flag "$MINER balance is $MINER_BALANCE"

    ALICE_ADDRESS=$(create_new_address $ALICE "$ALICE address")
    info_flag "$ALICE new address is $ALICE_ADDRESS"

    BOB_ADDRESS=$(create_new_address $BOB "$BOB address")
    info_flag "$BOB new address is $BOB_ADDRESS"

    SENT_BTC=20
    ALICE_TXID=$(bitcoin-cli -rpcwallet=$MINER sendtoaddress $ALICE_ADDRESS $SENT_BTC)
    BOB_TXID=$(bitcoin-cli -rpcwallet=$MINER sendtoaddress $BOB_ADDRESS $SENT_BTC)

    # transaction confirmation
    bitcoin-cli -rpcwallet="Miner" generatetoaddress 1 "$MINER_ADDRESS"
    ALICE_BALANCE=$(get_wallet_balance $ALICE)
    BOB_BALANCE=$(get_wallet_balance $BOB)

    info_flag "$ALICE balance is $ALICE_BALANCE and $BOB balance is $BOB_BALANCE"

    # 3. Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob.
    info_flag "3. Crear una dirección Multisig 2-de-2 combinando las claves públicas de Alice y Bob."
    ALICE_PUBKEY=$(bitcoin-cli -rpcwallet=$ALICE getaddressinfo $ALICE_ADDRESS | jq -r '.pubkey')
    BOB_PUBKEY=$(bitcoin-cli -rpcwallet=$BOB getaddressinfo $BOB_ADDRESS | jq -r '.pubkey')

    # MULTISIGN=$(bitcoin-cli createmultisig 2 "[\"$ALICE_PUBKEY\", \"$BOB_PUBKEY\"]")
    ALICE_MULTISIGN=$(bitcoin-cli -named -rpcwallet=$ALICE addmultisigaddress nrequired=2 keys="[\"$ALICE_PUBKEY\", \"$BOB_PUBKEY\"]")
    BOB_MULTISIGN=$(bitcoin-cli -named -rpcwallet=$BOB addmultisigaddress nrequired=2 keys="[\"$ALICE_PUBKEY\", \"$BOB_PUBKEY\"]")
    success_flag "Multisign added for $ALICE and $BOB"
    echo $ALICE_MULTISIGN | jq -r

    MULTISIGN_ADDRESS=$(echo $ALICE_MULTISIGN | jq -r '.address')

    info_flag "Import multisign address to $ALICE and $BOB"
    bitcoin-cli -named -rpcwallet=$ALICE importaddress address=$MULTISIGN_ADDRESS rescan="false"
    bitcoin-cli -named -rpcwallet=$BOB importaddress address=$MULTISIGN_ADDRESS rescan="false"

    # 4. Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.
    info_flag "4. Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos."

    ALICE_CHANGE_ADDRESS=$(create_raw_change_address "$ALICE")
    info_flag "$ALICE: raw change address $ALICE_CHANGE_ADDRESS"

    ALICE_BLOCK=$(bitcoin-cli -rpcwallet=$ALICE listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')
    info_flag "ALICE_BLOCK: $ALICE_BLOCK" 

    BOB_CHANGE_ADDRESS=$(create_raw_change_address "$BOB")
    info_flag "$BOB: raw change address $BOB_CHANGE_ADDRESS"

    BOB_BLOCK=$(bitcoin-cli -rpcwallet=$BOB listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')
    info_flag "BOB_BLOCK: $BOB_BLOCK" 

    MULTISIGN_BTC=20
    CHANGE_BTC=9.99998
    info_flag "Raw Transaction:" 
    info_flag "{\"inputs\": [$ALICE_BLOCK, $BOB_BLOCK], \"outputs\": [{\"$MULTISIGN_ADDRESS\": $MULTISIGN_BTC},{\"$ALICE_CHANGE_ADDRESS\": 10},{\"$BOB_CHANGE_ADDRESS\": $CHANGE_BTC}]}"

    # MULTISIGN_RAW_JSON=$(create_raw_sign_send_transaction "Miner" "" "")

    # info_flag "About to create raw transaction" 
    RAW_TRX=$(bitcoin-cli -named createrawtransaction inputs="[$ALICE_BLOCK, $BOB_BLOCK]" outputs="[{\"$MULTISIGN_ADDRESS\": $MULTISIGN_BTC},{\"$ALICE_CHANGE_ADDRESS\": 10},{\"$BOB_CHANGE_ADDRESS\": $CHANGE_BTC}]")
    # info_flag "RAW_TRX: $RAW_TRX"

    success_flag "Raw transaction created"
    echo $(bitcoin-cli -named decoderawtransaction hexstring=$RAW_TRX) | jq -r

    # Convert to PSBT
    PSBT=$(bitcoin-cli -named converttopsbt hexstring=$RAW_TRX)
    success_flag "PSBT Created: $PSBT"

    PSBT_1=$(bitcoin-cli -named createpsbt inputs="[$ALICE_BLOCK, $BOB_BLOCK]" outputs="[{\"$MULTISIGN_ADDRESS\": $MULTISIGN_BTC},{\"$ALICE_CHANGE_ADDRESS\": 10},{\"$BOB_CHANGE_ADDRESS\": $CHANGE_BTC}]")

    if [ "$PSBT" == "$PSBT_1" ]; 
        then     
            success_flag "PSBTs are equal"
        else     
            error_flag "PSBTs are not equal"
    fi

    bitcoin-cli -named analyzepsbt psbt=$PSBT | jq -r

    success_flag "2. Firmar la PSBT por Alice."
    ALICE_SIGNED_PSBT=$(bitcoin-cli -rpcwallet=$ALICE walletprocesspsbt $PSBT | jq -r '.psbt')
    success_flag "3. Firmar la PSBT por Alice."
    BOB_SIGNED_PSBT=$(bitcoin-cli -rpcwallet=$BOB walletprocesspsbt $PSBT | jq -r '.psbt')
    info_flag "$ALICE and $BOB signed original PSBT"

    PSBT_COMBINED=$(bitcoin-cli combinepsbt "[\"$ALICE_SIGNED_PSBT\", \"$BOB_SIGNED_PSBT\"]")
    success_flag "PSBT combined with $ALICE and $BOB PSBT"

    bitcoin-cli decodepsbt $PSBT_COMBINED | jq -r

    FINAL_PSBT=$(bitcoin-cli finalizepsbt $PSBT_COMBINED)
    success_flag "PSBT finalized"
    echo $FINAL_PSBT | jq -r

    FINAL_HEX_PSBT=$(echo $FINAL_PSBT | jq -r '.hex')

    PSBT_TRX=$(bitcoin-cli -named sendrawtransaction hexstring="$FINAL_HEX_PSBT")

    success_flag "PSBT_TRX: $PSBT_TRX" 

    # 5. Confirmar el saldo mediante la minería de algunos bloques adicionales.
    info_flag "5. Confirmar el saldo mediante la minería de algunos bloques adicionales."
    bitcoin-cli -rpcwallet="Miner" generatetoaddress 1 "$MINER_ADDRESS"

    ALICE_BALANCE=$(get_wallet_balance $ALICE)
    BOB_BALANCE=$(get_wallet_balance $BOB)

    # 6. Imprimir los saldos finales de Alice y Bob.
    info_flag "$ALICE balance is $ALICE_BALANCE and $BOB balance is $BOB_BALANCE"

    section_flag "Liquidar Multisig"

    info_flag "1. Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre Alice y Bob después de tener en cuenta las tarifas."

    ALICE_BLOCK=$(bitcoin-cli -rpcwallet=$ALICE listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')
    BOB_BLOCK=$(bitcoin-cli -rpcwallet=$BOB listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')

    ALICE_RETURN_ADDRESS=$(create_new_address $ALICE "$ALICE multisign return address")
    info_flag "$ALICE new multisign return address is $ALICE_RETURN_ADDRESS"

    BOB_RETURN_ADDRESS=$(create_new_address $BOB "$BOB multisign return address")
    info_flag "$BOB new multisign return address is $BOB_RETURN_ADDRESS"

    PSBT_BLOCK=$(bitcoin-cli -rpcwallet=Alice listunspent | jq -r --arg txid $PSBT_TRX '.[0] | select(.txid == $txid) | {"txid": .txid, "vout": .vout, "sequence": 1}')

    SPLIT_BTC=9.99999
    MULTISIGN_PSBT=$(bitcoin-cli -named createpsbt inputs="[$PSBT_BLOCK]" outputs="[{\"$ALICE_RETURN_ADDRESS\": $SPLIT_BTC},{\"$BOB_RETURN_ADDRESS\": $SPLIT_BTC}]")

    success_flag "Split PSBT Created $MULTISIGN_PSBT"

    info_flag "2. Firmar la PSBT por Alice."
    ALICE_SIGNED_MULTI_PSBT=$(bitcoin-cli -rpcwallet=$ALICE walletprocesspsbt $MULTISIGN_PSBT | jq -r '.psbt')

    bitcoin-cli analyzepsbt $ALICE_SIGNED_MULTI_PSBT

    info_flag "2. Firmar la PSBT por Bob."

    BOB_SIGNED_MULTI_PSBT=$(bitcoin-cli -rpcwallet=$BOB walletprocesspsbt $MULTISIGN_PSBT | jq -r '.psbt')

    bitcoin-cli analyzepsbt $BOB_SIGNED_MULTI_PSBT

    info_flag "3. Extraer y transmitir la transacción completamente firmada."

    MULTI_PSBT_COMBINED=$(bitcoin-cli combinepsbt "[\"$ALICE_SIGNED_MULTI_PSBT\", \"$BOB_SIGNED_MULTI_PSBT\"]")

    FINAL_MULTI_PSBT=$(bitcoin-cli finalizepsbt $MULTI_PSBT_COMBINED)
    success_flag "PSBT finalized"
    echo $FINAL_MULTI_PSBT | jq -r

    FINAL_MULTI_HEX_PSBT=$(echo $FINAL_MULTI_PSBT | jq -r '.hex')

    MULTI_PSBT_TRX=$(bitcoin-cli -named sendrawtransaction hexstring="$FINAL_MULTI_HEX_PSBT")

    success_flag "MULTI_PSBT_TRX: $MULTI_PSBT_TRX" 

    info_flag "5. Imprimir los saldos finales de Alice y Bob."

    bitcoin-cli -rpcwallet="Miner" generatetoaddress 1 "$MINER_ADDRESS"
    ALICE_BALANCE=$(get_wallet_balance $ALICE)
    BOB_BALANCE=$(get_wallet_balance $BOB)

    success_flag "$ALICE balance is $ALICE_BALANCE and $BOB balance is $BOB_BALANCE"
}

week_4() {
    MINER="Miner"
    EMPLOYEE="Employee"
    EMPLOYER="Employer"
    MINER_ADDRESS=$(get_address_by_label "Miner" "Mining Reward")

    section_flag "xwazzo: Week 4 solution"

    info_flag "Crea tres monederos: Miner, Empleado y Empleador."
    create_wallet "$EMPLOYEE"
    success_flag "$EMPLOYEE wallet created"

    create_wallet "$EMPLOYER"
    success_flag "$EMPLOYER wallet created"

    info_flag "2. Fondea los monederos generando algunos bloques para Miner y enviando algunas monedas al Empleador"
    MINER_BALANCE=$(bitcoin-cli -rpcwallet=$MINER getbalance)
    success_flag "$MINER balance is $MINER_BALANCE"

    EMPLOYEE_ADDRESS=$(create_new_address $EMPLOYEE "$EMPLOYEE address")
    info_flag "$EMPLOYEE new address is $EMPLOYEE_ADDRESS"

    EMPLOYER_ADDRESS=$(create_new_address $EMPLOYER "$EMPLOYER address")
    info_flag "$EMPLOYER new address is $EMPLOYER_ADDRESS"

    SENT_TO_EMPLOYER=50
    EMPLOYER_TXID=$(bitcoin-cli -rpcwallet=$MINER sendtoaddress $EMPLOYER_ADDRESS $SENT_TO_EMPLOYER)

    # transaction confirmation
    bitcoin-cli -rpcwallet="Miner" generatetoaddress 1 "$MINER_ADDRESS"
    EMPLOYER_BALANCE=$(get_wallet_balance $EMPLOYER)

    info_flag "$EMPLOYER balance is $EMPLOYER_BALANCE and $EMPLOYEE balance is $EMPLOYEE_BALANCE"

    info_flag "3. Crea una transacción de salario de 40 BTC, donde el Empleador paga al Empleado."

    EMPLOYER_BLOCK=$(bitcoin-cli -rpcwallet=$EMPLOYER listunspent | jq -r '.[0] | {"txid": .txid, "vout": .vout, "sequence": 1}')

    EMPLOYEE_SALARY=40
    FEE=0.00000350
    EMPLOYER_CHANGE=$(echo $SENT_TO_EMPLOYER - $EMPLOYEE_SALARY - $FEE | bc)
    BLOCK_COUNT=$(bitcoin-cli getblockcount)
    LOCKTIME=$(echo $BLOCK_COUNT + 500 | bc)
    # 4. Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción no puede incluirse en el bloque hasta que se haya minado el bloque 500.
    info_flag "4. Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción no puede incluirse en el bloque hasta que se haya minado el bloque 500."
    RAW_TRX=$(bitcoin-cli -named createrawtransaction inputs="[$EMPLOYER_BLOCK]" outputs="[{\"$EMPLOYEE_ADDRESS\": $EMPLOYEE_SALARY},{\"$EMPLOYER_ADDRESS\": $EMPLOYER_CHANGE}]" locktime="$LOCKTIME")

    # 5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción.
    info_flag "5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción."
    SIGNED_RAW_TRX=$(bitcoin-cli -rpcwallet="$EMPLOYER" signrawtransactionwithwallet "$RAW_TRX")
    # info_flag "SIGNED_RAW_TRX: $SIGNED_RAW_TRX"

    bitcoin-cli sendrawtransaction $(echo $SIGNED_RAW_TRX | jq -r .hex)

    error_flag "Error: No podemos transmitir la trasacción"
    info_flag "El error ocurre porque no está permitido enviar una transacción con un locktime futuro, únicamente los que están a punto de ser válidos por el numero de bloques."

    # 6. Mina hasta el bloque 500 y transmite la transacción.
    info_flag "6. Mina hasta el bloque 500 y transmite la transacción"
    info_flag "Mining 500 blocks"
    bitcoin-cli -rpcwallet="Miner" generatetoaddress 500 "$MINER_ADDRESS"

    info_flag "Sending transaction after 500 blocks"
    bitcoin-cli sendrawtransaction $(echo $SIGNED_RAW_TRX | jq -r .hex)

    DECODE_RAW_TRX=$(bitcoin-cli decoderawtransaction $RAW_TRX)
    info_flag "DECODE_RAW_TRX: $DECODE_RAW_TRX"

    bitcoin-cli -rpcwallet="Miner" generatetoaddress 1 "$MINER_ADDRESS"

    # 7. Imprime los saldos finales del Empleado y Empleador.
    info_flag "7. Imprime los saldos finales del Empleado y Empleador."

    EMPLOYER_BALANCE=$(get_wallet_balance $EMPLOYER)
    EMPLOYEE_BALANCE=$(get_wallet_balance $EMPLOYEE)

    success_flag "$EMPLOYER balance is $EMPLOYER_BALANCE and $EMPLOYEE balance is $EMPLOYEE_BALANCE"
}

run_program() {
    install_dependencies
    sleep 2
    install_node
    sleep 2
    start_node
    sleep 2
    create_wallet_and_mine_to_address "Miner" "Mining Reward"
    sleep 2
    week_4git bran
}

run_program
