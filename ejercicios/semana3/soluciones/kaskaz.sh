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
    #PLATFORM="x86_64"
    PLATFORM="aarch64"
    BITCOIN="bitcoin-core-25.1"
    BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

    # Descargamos los binarios de Bitcoin Core
    wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN-$PLATFORM-linux-gnu.tar.gz
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
    tar xzf $BITCOINPLAIN-$PLATFORM-linux-gnu.tar.gz

    # Instala los ejecutables en las rutas por defecto del sistema
    sudo install -m 0755 -o root -g root -t /usr/local/bin $BITCOINPLAIN/bin/*

    # Instala los manuales
    sudo cp -r $BITCOINPLAIN/share/man/man1 /usr/local/share/man
    command -v mandb && sudo mandb 

    # Elimina los archivos descargados
    rm -rf $BITCOINPLAIN $BITCOINPLAIN-$PLATFORM-linux-gnu.tar.gz guix.sigs SHA256SUMS.asc SHA256SUMS

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

    killall bitcoind
    sleep 1
    rm -fr ~/.bitcoin
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
        kill -s TERM $$
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
        kill -s TERM $$
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


echo '''
**************************
* Descarga e instalación *
**************************
'''
#install_bitcoin_core

echo '''
**********************
* Iniciando bitcoind *
**********************
'''
bitcoind -daemon
sleep 1

echo '''
***************
* Ejercicio 1 *
***************
'''
echo "Creando cartera 'Miner'"
create_wallet_without_descriptor "Miner"
echo "Creando cartera 'Alice'"
create_wallet_without_descriptor "Alice"
echo "Creando cartera 'Bob'"
create_wallet_without_descriptor "Bob"

echo '''
***************
* Ejercicio 2 *
***************
'''
echo "Creando dirección para recompensa de minado en la cartera 'Miner'"
miner_address=$(create_address "Miner" "Recompensa de Minería")
echo "Creada dirección: '$miner_address'"

mine_until_balance_equals "Miner" "$miner_address" "50"




echo '''
**************************
* Limpieza *
**************************
'''
# clean
# echo "Se ha detenido el servicio y borrado la configuración."