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
    bitcoin-cli -named createwallet wallet_name=$1 descriptors=true
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
    create_wallet $1
    success_flag "$1 wallet created"
    ADDRESS=$(create_new_address $1 "$2")
    success_flag "created address on wallet $1 label $2"
    info_flag "address: $ADDRESS" 

    info_flag "get pubkey on wallet $1 address $ADDRESS"
    PUB_KEY=$(get_address_public_key $1 $ADDRESS)
    info_flag $PUB_KEY

    mine_to_address_until_more_than_x $1 $ADDRESS 149
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

run_program() {
    install_dependencies
    sleep 2
    install_node
    sleep 2
    start_node
    sleep 2
    create_wallet_and_mine_to_address "Miner" "Mining Reward"
    sleep 2
    week_2
}

run_program
