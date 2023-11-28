#!/bin/bash

# install_bitcoin_core - Instala bitcoin-core a partir de los binarios.
#
# Descarga los archivos binarios de bitcoin-core, comprueba las firmas de
# verificación, los instala, borra las descargas, crea el fichero de configuración
# e inicia el servicio.
install_bitcoin_core() {

    # Actualiza los paquetes del sistema
    sudo apt update
    sudo apt upgrade -y

    # Instala las dependencias requeridas por bitcoin
    sudo apt-get install haveged gnupg dirmngr xxd -y

    # Versión a descargar
    BITCOIN="bitcoin-core-25.1"
    BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

    # Descargamos los binarios de Bitcoin Core
    wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-x86_64-linux-gnu.tar.gz
    # Y los archivos con las sumas de verificación y las firmas PGP
    wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc
    wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS

    # Clonamos el repositorio con las claves públicas de los autores del proyecto
    git clone https://github.com/bitcoin-core/guix.sigs.git
    for file in ./guix.sigs/builder-keys/*.gpg; do gpg --import "$file"; done

    # Verificamos la autenticidad del archivo SHA256SUMS 
    SHASIG=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature"`
    SHACOUNT=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature" | wc -l`

    if [[ "$SHASIG" ]]
    then
        echo "$0 - Verificación de firma correcta: Encontradas $SHACOUNT firmas correctas."
        echo "$SHASIG"
    else
        (>&2 echo "$0 - Error de verificación de firmas: No se ha podido verificar el archivo SHA256SUMS")
    fi

    # Busca en el directorio actual los archivos indicados en SHA256SUMS y 
    # comprueba sus sumas de verificación
    SHACHECK=`sha256sum -c --ignore-missing < SHA256SUMS 2>&1 | grep "OK"`

    if [ "$SHACHECK" ]
    then
    echo "$0 - Verificación exitosa de la firma binaria. Comprobados los archivos: $SHACHECK"
    else
        (>&2 echo "$0 - Verificación de SHA incorrecta!")
    fi

    # Extrae los binarios
    tar xzf $BITCOINPLAIN-x86_64-linux-gnu.tar.gz

    # Instala los ejecutables en las rutas por defecto del sistema
    sudo install -m 0755 -o root -g root -t /usr/local/bin $BITCOINPLAIN/bin/*

    # Instala los manuales
    sudo cp -r $BITCOINPLAIN/share/man/man1 /usr/local/share/man
    command -v mandb && sudo mandb 

    # Elimina los archivos descargados
    rm -rf $BITCOINPLAIN $BITCOINPLAIN-x86_64-linux-gnu.tar.gz guix.sigs SHA256SUMS.asc SHA256SUMS

    # Crea la carpeta de datos del nodo en la ubicación por defecto
    mkdir ~/.bitcoin

    # Crea el archivo de configuración del nodo
    cat >> ~/.bitcoin/bitcoin.conf << EOF
regtest=1
fallbackfee=0.0001
server=1
txindex=1
EOF
}

# clean - Realiza limpieza de final de ejecución.
#
# Detiene bitcoin-core y borra los archivos de configuración.
clean() {

    echo "Deteniendo el servicio y borrando la configuración"
    killall bitcoind
    sleep 1
    rm -fr ~/.bitcoin
    kill -s TERM $$
}

# create_wallet_without_descriptor - Crea una nueva billetera sin descriptor.
#
# Comprueba que se ha creado comparando el nombre de billetera devuelto por
# bitcoin-cli. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - El nombre de la billetera que se desea crear.
create_wallet_without_descriptor() {

    local wallet_name=$1
    
    local createwallet_output=$(bitcoin-cli -named createwallet wallet_name="$wallet_name" descriptors="false")
    local created_name=$(echo $createwallet_output | jq -r '.name')
    
    if [ "$created_name" != "$wallet_name" ]
    then
        (>&2 echo "Error. No se ha podido crear la cartera")
        clean
    fi
}

# create_address - Crea una nueva dirección.
#
# Comprueba que se ha creado verificando que bitcoin-cli ha devuelto una cadena
# de texto. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - Nombre de la cartera en la que crear la dirección.
#   $2 - Etiqueta descriptiva para la nueva dirección.
create_address() {

    local wallet_name=$1
    local wallet_label=$2

    local createaddress_output=$(bitcoin-cli -rpcwallet="$wallet_name" -named getnewaddress label="$wallet_label")

    if [ ! -z "$createaddress_output" ]
    then
        echo "$createaddress_output"
    else
        (>&2 echo "Error. No se ha podido crear una dirección en la cartera '$wallet_name'")
        clean
    fi
}

# create_change_address - Crea una nueva dirección para el cambio.
#
# Comprueba que se ha creado verificando que bitcoin-cli ha devuelto una cadena
# de texto. Muestra un mensaje de error y detiene la ejecución si no es así.
#
# Parámetros:
#   $1 - Nombre de la cartera en la que crear la dirección.
create_change_address() {

    local wallet_name=$1

    local createaddress_output=$(bitcoin-cli -rpcwallet="$wallet_name" getrawchangeaddress legacy)

    if [ ! -z "$createaddress_output" ]
    then
        echo "$createaddress_output"
    else
        (>&2 echo "Error. No se ha podido crear una dirección de cambio en la cartera '$wallet_name'")
        clean
    fi
}

# mine_until_balance_equals - Mina bloques hasta el saldo disponible sea el indicado.
#
# Mina nuevos bloques recibiendo la recompensa en la dirección indicada. Tras cada
# bloque comprueba el saldo y si el saldo disponible no es el esperado, mina otro bloque.
# Repite hasta que el saldo sea suficiente.
#
# Nota 1: Si se indica una dirección que no pertenece a la cartera indicada, seguirá minando
#         bloques hasta que se cancele el proceso manualmente.
#
# Parámetros:
#   $1 - Nombre de la cartera asociada a la dirección de recompensa.
#   $2 - Dirección de recompensa.
#   $3 - Saldo objetivo.
mine_until_balance_equals() {

    local wallet_name=$1
    local mining_address=$2
    local expected_balance=$3

    local balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)

    echo ""
    echo -n "Minando bloques... "

    while (( $(echo "$balance" "$expected_balance" | awk '{if ($1 + 0 < $2 + 0) print 1; else print 0;}') ))
    do
        bitcoin-cli generatetoaddress 1 "$mining_address" > /dev/null
        local blocks_mined=$(($blocks_mined + 1))
        echo -n "$blocks_mined "
        balance=$(bitcoin-cli -rpcwallet="$wallet_name" getbalance)
    done

    echo ""
    echo "Se minaron $blocks_mined bloques hasta que el saldo alcanzó o superó '$expected_balance'"
    echo ""
    echo "Balance actual: $balance"
}

# find_first_utxos - Devuelve el número solicitado de UTXOs disponibles.
#
# Obtiene el número de UTXOs solicitado de la lista total de UTXOs y extrae
# los campos 'txid' y 'vout'.
#
# Parámetros:
#   $1 - Nombre de la cartera asociada a la dirección de recompensa.
#   $2 - Número de UTXOs deseados.
#   $3 - Seleccionar UTXOs de una dirección específica (opcional).
find_first_utxos() {

    local wallet_name=$1
    local requested_utxos_count=$2
    local filter_address=$3

    local addresses=$(jq -n --arg var "$address" 'if $var | length > 0 then [$var] else [] end')
    local utxos=$(bitcoin-cli -rpcwallet="$wallet_name" -named listunspent addresses="$addresses" | jq '[.[:'$requested_utxos_count'][] | { txid: .txid, vout: .vout }]')
    local obtained_utxos_count=$(echo $utxos | jq 'length')

    if [ "$requested_utxos_count" == "$obtained_utxos_count" ]
    then
        echo "$utxos"
    else
        (>&2 echo "Error. Se solicitaron '$requested_utxos_count' UTXOs, pero se han obtenido '$obtained_utxos_count'")
        clean
    fi
}

# compose_transaction - Crea una transacción (no RBF) con los datos recibidos.
#
# Compone una transacción conteniendo todos los UTXOs recibidos.
# Opcionalmente, devuelve a una dirección de cambio la cantidad indicada.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de destino.
#   $3 - Importe a enviar.
#   $4 - Dirección de cambio (opcional).
#   $5 - Importe a devolver (opcional).
compose_transaction() {

    local utxos=$1
    local destination_address=$2
    local amount=$3
    local change_address=$4
    local change_amount=$5

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout })')
    local outputs='''{ "'$destination_address'": '$amount' }'''

    if [[ -n "$change_address" && -n "$change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$change_address'": '$change_amount' }')
    fi

    local tx_raw=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

    if [ ! -z "$tx_raw" ]
    then
        echo "$tx_raw"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        clean
    fi
}

# compose_transaction_with_locktime - Crea una transacción con locktime con los datos recibidos.
#
# Compone una transacción con locktime conteniendo todos los UTXOs recibidos.
# Opcionalmente, devuelve a una dirección de cambio la cantidad indicada.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de destino.
#   $3 - Importe a enviar.
#   $4 - Valor del locktime.
#   $5 - Dirección de cambio (opcional).
#   $6 - Importe a devolver (opcional).
compose_transaction_with_locktime() {

    local utxos=$1
    local destination_address=$2
    local amount=$3
    local locktime=$4
    local change_address=$5
    local change_amount=$6

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout })')
    local outputs='''{ "'$destination_address'": '$amount' }'''

    if [[ -n "$change_address" && -n "$change_amount" ]]
    then
        outputs=$(echo $outputs | jq '. + { "'$change_address'": '$change_amount' }')
    fi

    local tx_raw=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs" locktime="$locktime")

    if [ ! -z "$tx_raw" ]
    then
        echo "$tx_raw"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        clean
    fi
}

# compose_data_transaction - Crea una transacción para almacenar datos en la blockchain.
#
# Compone una transacción conteniendo todos los UTXOs recibidos, e incluyendo datos
# en la blockchain por medio de OP_RETURN. Devuelve a una dirección de cambio la 
# cantidad indicada.
#
# Parámetros:
#   $1 - JSON con los UTXOs a incluir.
#   $2 - Dirección de cambio.
#   $3 - Importe a devolver.
#   $4 - Datos a insertar en la blockchain (en formato hexadecimal).
compose_data_transaction() {

    local utxos=$1
    local change_address=$2
    local change_amount=$3
    local data=$4

    local inputs=$(echo $utxos | jq 'map({ txid: .txid, vout: .vout })')
    local outputs='''{ "data": "'$data'", "'$change_address'": '$change_amount'  }'''

    local tx_raw=$(bitcoin-cli -named createrawtransaction inputs="$inputs" outputs="$outputs")

    if [ ! -z "$tx_raw" ]
    then
        echo "$tx_raw"
    else
        (>&2 echo "Error. No se ha podido componer la transacción solicitada")
        clean
    fi
}

# sign_and_send_transaction - Firma y envía una transacción.
#
# Firma la transacción con la clave privada de la cartera indicada y la envía al nodo.
#
# Parámetros:
#   $1 - Nombre de la cartera cuya clave privada firmará la transacción.
#   $2 - Transacción (formato RAW).
sign_and_send_transaction() {

    local sender_wallet_name=$1
    local transaction=$2

    local sign_tx_outp=$(bitcoin-cli -rpcwallet="$sender_wallet_name" signrawtransactionwithwallet $transaction)
    local signed_tx=$(echo $sign_tx_outp | jq -r '.hex')

    if [ -z "$signed_tx" ]
    then
        (>&2 echo "Error. No se ha podido firmar la transacción")
        clean
    fi

    local tx_hash=$(bitcoin-cli sendrawtransaction "$signed_tx")

    if [ ! -z "$tx_hash" ]
    then
        echo "$tx_hash"
    else
        (>&2 echo "Error. No se ha podido enviar la transacción firmada")
        clean
    fi
}

# sign_transaction - Firma una transacción.
#
# Firma la transacción con la clave privada de la cartera indicada.
#
# Parámetros:
#   $1 - Nombre de la cartera cuya clave privada firmará la transacción.
#   $2 - Transacción (formato RAW).
sign_transaction() {

    local sender_wallet_name=$1
    local transaction=$2

    local sign_tx_outp=$(bitcoin-cli -rpcwallet="$sender_wallet_name" signrawtransactionwithwallet $transaction)
    local signed_tx=$(echo $sign_tx_outp | jq -r '.hex')

    if [ ! -z "$signed_tx" ]
    then
        echo "$signed_tx"
        (>&2 echo "Error. No se ha podido firmar la transacción")
    fi
}

# send_transaction - Envía una transacción.
#
# Parámetros:
#   $1 - Transacción firmada.
send_transaction() {

    local signed_tx=$1

    local tx_hash=$(bitcoin-cli sendrawtransaction "$signed_tx")

    if [ ! -z "$tx_hash" ]
    then
        echo "$tx_hash"
    else
        (>&2 echo "Error. No se ha podido enviar la transacción firmada")
    fi
}


echo """
**************************
* Descarga e instalación *
**************************
"""
install_bitcoin_core

echo """
**********************
* Iniciando bitcoind *
**********************
"""
bitcoind -daemon
sleep 1


echo """
************************************************
* Configurar un contrato Timelock. Ejercicio 1 *
************************************************
"""
echo "Creando cartera 'Miner'"
create_wallet_without_descriptor "Miner"
echo "Creando cartera 'Empleado'"
create_wallet_without_descriptor "Empleado"
echo "Creando cartera 'Empleador'"
create_wallet_without_descriptor "Empleador"

echo """
************************************************
* Configurar un contrato Timelock. Ejercicio 2 *
************************************************
"""
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "500"

echo ""
echo "Creando dirección de recepción para 'Empleador'"
employer_address=$(create_address "Empleador" "Recepción de fondos")
echo "Creada dirección: '$employer_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Miner'"
miner_change_address=$(create_change_address "Miner")
echo "Creada dirección: '$miner_change_address'"

echo ""
echo "Componiendo una transacción para 'Empleador' con los primeros 5 UTXOs de 'Miner'"
utxos=$(find_first_utxos "Miner" "5")
amount="200"
change_amount="49.9999"
send_employer_tx=$(compose_transaction "$utxos" "$employer_address" "$amount" "$miner_change_address" "$change_amount")

echo ""
echo "Firmando la transacción y enviándola"
send_employer_tx_hash=$(sign_and_send_transaction "Miner" "$send_employer_tx")
echo "Enviada transacción '$send_employer_tx_hash'"

echo ""
echo "Minando un bloque para procesar la transacción"
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo """
*****************************************************
* Configurar un contrato Timelock. Ejercicios 3 y 4 *
*****************************************************
"""
echo "Creando dirección de recepción para 'Empleado'"
employee_address=$(create_address "Empleado" "Recepción de salario")
echo "Creada dirección: '$employee_address'"

echo ""
echo "Creando dirección para recibir el cambio en la cartera 'Empleador'"
employer_change_address=$(create_change_address "Empleador")
echo "Creada dirección: '$employer_change_address'"

echo ""
echo "Componiendo una transacción para 'Empleado' con el primer UTXO de 'Empleador'"
echo "y un locktime absoluto de 500 bloques"
utxos=$(find_first_utxos "Empleador" "1")
amount="40"
change_amount="159.9999"
locktime="500"
send_employee_tx=$(compose_transaction_with_locktime \
    "$utxos" "$employee_address" "$amount" "$locktime" \
    "$employer_change_address" "$change_amount" \
)

echo """
************************************************
* Configurar un contrato Timelock. Ejercicio 5 *
************************************************
"""
echo "Firmando la transacción y enviándola"
signed_send_employee_tx=$(sign_transaction "Empleador" "$send_employee_tx")
send_employee_tx_hash=$(send_transaction "$signed_send_employee_tx")

echo """
No se ha podido enviar la transacción a la red ya que por defecto la configuración
de la mempool de nuestro nodo no acepta las transacciones si su locktime no ha pasado,
pero 'Empleador' puede enviar la transacción firmada a 'Employee' para que él mismo la 
envíe llegado el momento.

************************************************
* Configurar un contrato Timelock. Ejercicio 6 *
************************************************

Vamos a proceder a minar bloques hasta que la altura de bloque sea superior a 500, y
a volver a intentarlo.

Minando 400 bloques (terminamos más allá del bloque 500)
"""
bitcoin-cli -rpcwallet="Miner" -generate 400 > /dev/null

echo "Enviando la transacción"
send_employee_tx_hash=$(send_transaction "$signed_send_employee_tx")
echo "Enviada transacción '$send_employee_tx_hash'"

echo ""
echo "Minando un bloque para procesar la transacción"
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo ""
echo "Saldos de cada participante:"
employer_balance=$(bitcoin-cli -rpcwallet="Empleador" getbalance)
employee_balance=$(bitcoin-cli -rpcwallet="Empleado" getbalance)
echo "Saldo de Empleador: $employer_balance BTC"
echo "Saldo de Empleado: $employee_balance BTC"

echo """
**********************************************
* Gastar desde el Timelock. Ejercicios 1 y 2 *
**********************************************
"""
echo "Creando dirección para recibir el cambio en la cartera 'Empleado'"
employee_change_address=$(create_change_address "Empleado")
echo "Creada dirección: '$employee_change_address'"

echo """
Componiendo una transacción para almacenamiento de datos, con el primer UTXO
de 'Empleado', pagando únicamente la comisión y devolviendo el campo a sí mismo.
"""
utxos=$(find_first_utxos "Empleado" "1")
change_amount="39.9999"
data=$(echo "He recibido mi salario, ahora soy rico" | xxd -p -c 1000000)
employee_data_tx=$(compose_data_transaction "$utxos" "$employee_change_address" "$change_amount" "$data")

echo """
*****************************************
* Gastar desde el Timelock. Ejercicio 3 *
*****************************************
"""
echo "Firmando la transacción y enviándola"
employee_data_tx_hash=$(sign_and_send_transaction "Empleado" "$employee_data_tx")
echo "Enviada transacción '$employee_data_tx_hash'"

echo ""
echo "Minando un bloque para procesar la transacción"
bitcoin-cli -rpcwallet="Miner" -generate 1 > /dev/null

echo """
*****************************************
* Gastar desde el Timelock. Ejercicio 4 *
*****************************************
"""
echo "Saldos de cada participante:"
employer_balance=$(bitcoin-cli -rpcwallet="Empleador" getbalance)
employee_balance=$(bitcoin-cli -rpcwallet="Empleado" getbalance)
echo "Saldo de Empleador: $employer_balance BTC"
echo "Saldo de Empleado: $employee_balance BTC"

echo """
***********************************
* Gastar desde el Timelock. Bonus *
***********************************

Vamos a mostrar las propiedades de la transacción de datos y a observar
cómo han quedado registrados.
"""
employee_data_tx_hash=$(bitcoin-cli decoderawtransaction $(bitcoin-cli getrawtransaction "$employee_data_tx_hash"))
echo "$employee_data_tx_hash" | jq

echo """
Podemos ver que el 'scriptPubKey' de la primera salida de esta transacción
es de tipo 'nulldata', y que el campo 'asm' contiene la instrucción 'OP_RETURN'
seguida de una cadena hexadecimal.

En nuestro código, para incluir el texto en el bloque, hemos tenido que convertir
el texto a su representación hexadecimal para poder incluirlo en la transacción,
y así es como se muestra en el JSON de la misma.

Vamos a extraer ese dato y convertirlo a su valor en texto ASCII.
"""

asm=$(echo "$employee_data_tx_hash" | jq -r '.vout[0].scriptPubKey.asm')
data=$(echo "$asm" | sed 's/OP_RETURN //g')
text=$(echo "$data" | xxd -r -p)
echo "La cadena hexadecimal '$data'"
echo "Corresponde al texto '$text'"

echo """
**************************
* Limpieza *
**************************
"""
clean
