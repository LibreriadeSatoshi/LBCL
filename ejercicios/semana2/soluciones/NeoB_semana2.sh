
# !/bin/bash
# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 1.
# Autor: NeoBishop

echo
echo Para iniciar el ejercicio se aconseja disponer de un entorno de trabajo lo más estándard posible.
echo La recomendación es un Ubuntu 22.04 LTS con los siguientes paquetes instalados
echo
echo -e "bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd\n"



echo -e "******************************************"
echo -e "******INICIANDO INSTALACIÓN PAQUETES******"
echo -e "******************************************\n"

sudo apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd

# Detener bitcoind y limpiar los archivos descargados para empezar de 0.


bitcoin-cli stop
sleep 7
        sudo rm -r $HOME/.bitcoin
        sudo rm /usr/local/bin/bitcoin*
        sudo rm -r $HOME/bitcoin*
        sudo rm $HOME/SHA256SUMS*
        sudo rm -r $HOME/guix.sigs

sleep 3

# Definir una variable.
version_bitcoin="25.0"

echo
echo -e "************************************************************"
echo -e "******INICIANDO DESCARGA E INSTALACION DE BITCOIN CORE******"
echo -e "************************************************************\n"



echo -e "Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/\n"

wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS
wget --no-verbose --show-progress https://bitcoin.org/bin/bitcoin-core-${version_bitcoin}/SHA256SUMS.asc

echo
echo -e "Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos."
echo -e "Imprimir un mensaje en la terminal: Verificación exitosa de la firma binaria\n"
echo

sha256sum --ignore-missing --check SHA256SUMS

echo
echo -e "Verificación exitosa del checksum\n"

sleep 5

git clone https://github.com/bitcoin-core/guix.sigs
gpg --import guix.sigs/builder-keys/*
gpg --verify SHA256SUMS.asc

echo
echo -e "Verificación exitosa de la firma binaria\n"
echo

sleep 5

echo
echo -e "Copiar los binarios descargados a la carpeta /usr/local/bin/.\n"
echo

tar -xvf bitcoin-${version_bitcoin}-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${version_bitcoin}/bin/*

sleep 5

echo
echo -e "Crear un archivo bitcoin.conf en el directorio de datos /home/<nombre-de-usuario>/.bitcoin/"
echo -e "Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:\n"
echo

mkdir $HOME/.bitcoin
touch $HOME/.bitcoin/bitcoin.conf
echo "regtest=1" >> $HOME/.bitcoin/bitcoin.conf
echo "fallbackfee=0.0001" >> $HOME/.bitcoin/bitcoin.conf
echo "server=1" >> $HOME/.bitcoin/bitcoin.conf
echo "txindex=1" >> $HOME/.bitcoin/bitcoin.conf

echo "regtest=1"
echo "fallbackfee=0.0001"
echo "server=1"
echo "txindex=1"

echo
echo -e "******************************"
echo -e "******INICIANDO BITCOIND******"
echo -e "******************************\n"
echo

bitcoind -daemon
sleep 6

# Script curso Librería de satoshi - Aprendiendo Bitcoin desde la Línea de Comandos. Ejercicio semana 2.
# Autor: NeoBishop


# ENUNCIADO DEL PROBLEMA

# Ahora que tenemos un nodo de Bitcoin en funcionamiento, con una billetera conectada, en este ejercicio realizaremos algunos
# flujos de trabajo básicos de uso de billeteras de Bitcoin utilizando scripts de bash y la interfaz de línea de comandos bitcoin-cli.
# Nos enfocaremos en aumentar la tarifa utilizando los mecanismos de Replace-By-Fee (RBF) y Child-Pays-for-Parent (CPFP).

# A menudo, las billeteras necesitan aumentar las tarifas en momentos de altas tasas de tarifas.
# Hay dos formas de aumentar las tarifas, RBF y CPFP.
# Ambos utilizan mecanismos diferentes para aumentar la tarifa, pero no pueden usarse juntos.
# Intentar RBF una transacción invalidaría la CPFP, ya que la transacción secundaria no puede ser válida si su transacción principal se elimina del "mempool".

# El siguiente ejercicio intenta demostrar esa situación.

echo -e "******************************"
echo -e "******EJERCICIO SEMANA 2******"
echo -e "******************************"


echo -e "1. Crear dos billeteras llamadas Miner y Trader.\n"

bitcoin-cli -named createwallet wallet_name="Miner" descriptors=true
bitcoin-cli -named createwallet wallet_name="Trader" descriptors=true

echo -e "2. Fondear la billetera Miner con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).\n"

miner_dir=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Saldo Inicial de la Dirección Miner")

echo -e "Nueva dirección de la billetera  Miner:${miner_dir}\n"

bitcoin-cli generatetoaddress 103 ${miner_dir}
balance_miner=$(bitcoin-cli -rpcwallet=Miner getbalance)

echo -e "Imprimir el saldo de la billetera Miner:${balance_miner}"


echo -e "*************************************************************************************************************"
echo -e "3. Crear una transacción desde Miner a Trader con la siguiente estructura (llamémosla la transacción parent):"
echo -e "*************************************************************************************************************\n"

echo -e "Entrada[0]: Recompensa en bloque de 50 BTC.\n"
        txid_miner=($(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .txid')) # se obtienen todos lot txid en un array
        vout_miner=($(bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .vout')) # se obtiene  todos los vouts en un array
        echo -e "${txid_miner[0]}"
        echo -e "${vout_miner[0]} \n"

echo -e "Entrada[1]: Recompensa en bloque de 50 BTC.\n"
        echo -e "${txid_miner[1]}"
        echo -e "${vout_miner[1]} \n"

echo -e "Salida[0]: 70 BTC para Trader.\n"
        envio_trader=$(bitcoin-cli -rpcwallet=Trader getnewaddress "Dirección para envío a Trader")
        echo -e "Nueva direccion en la cartera Trader: $envio_trader \n"

echo -e "Salida[1]: 29.99999 BTC de cambio para Miner.\n"
        cambio_miner=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Cambio Miner")
                echo -e "Nueva direccion en la cartera Miner: $cambio_miner \n"
sleep 3

echo -e "Activar RBF (Habilitar RBF para la transacción).\n"

txparent=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'${txid_miner[0]}'", "vout": '${vout_miner[0]}', "sequence": 1 }, { "txid": "'${txid_miner[1]}'", "vout": '${vout_miner[1]}', "sequence": 1 } ]''' outputs='''[ { "'$envio_trader'": 70 }, { "'$cambio_miner'": 29.99999 }] ''')

echo -e "Transaccion en crudo: $txparent \n"
        bitcoin-cli decoderawtransaction $txparent| jq -r '.vin | .[]'

echo -e "***********************************************************************"
echo -e "4. Firmar y transmitir la transacción parent, pero no la confirmes aún:"
echo -e "***********************************************************************\n"

        signedtx=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txparent | jq -r '.hex')
        txidparent=$(bitcoin-cli sendrawtransaction $signedtx)

echo -e "Se muestra el ID de transacción "parent": $txidparent \n"

echo -e "**********************************************************************************************"
echo -e "5. Realizar consultas al "mempool" del nodo para obtener los detalles de la transacción parent."
echo -e "   Utiliza los detalles para crear una variable JSON con la siguiente estructura:"
echo -e "**********************************************************************************************\n"


        input0=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vin[0] | { txid: .txid, vout: .vout }')
        input1=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vin[1] | { txid: .txid, vout: .vout }')
        output0=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vout[0] | { script_pubkey: .scriptPubKey , amount: .value }')
        output1=$(bitcoin-cli decoderawtransaction $signedtx | jq -r '.vout[1] | { script_pubkey: .scriptPubKey , amount: .value }')
        txfee=$(bitcoin-cli getmempoolentry $txidparent | jq -r '.fees .base')
        txweight=$(bitcoin-cli getmempoolentry $txidparent | jq -r '.weight')
        json='{ "input": [ '$input0', '$input1' ], "output": [ '$output0', '$output1' ], "Fees": '$txfee', "Weight": '$txweight' }'


echo -e "*******************************************"
echo -e "6. Imprime el JSON anterior en la terminal."
echo -e "*******************************************\n"

echo $json | jq

echo -e "******************************************************************************************************"
echo -e "7. Crea una nueva transacción que gaste la transacción anterior (parent). Llamémosla transacción child."
echo -e "******************************************************************************************************\n"

echo "Entrada[0]: Salida de Miner de la transacción parent."
echo "Salida[0]: Nueva dirección de Miner. 29.99998 BTC."

        child=$(bitcoin-cli -rpcwallet=Miner getnewaddress "Nueva dirección Child")
        txchild=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'$txidparent'", "vout": 1} ]''' outputs='''[ { "'$child'": 29.99998 } ]''')
        txchildfirmada=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txchild | jq -r '.hex')
        txidchild=$(bitcoin-cli sendrawtransaction $txchildfirmada)
echo -e "ID de transaccion child: $txidchild \n"
        bitcoin-cli decoderawtransaction $txchildfirmada | jq

echo -e "*************************************************************************************"
echo -e "8. Realiza una consulta getmempoolentry para la transacción clild y muestra la salida."
echo -e "*************************************************************************************\n"

echo -e "Se muestran los detalles de la transacción child mediante el comando bitcoin-cli getmempoolentry $txidchild "

        bitcoin-cli getmempoolentry $txidchild | jq

echo -e "Aparecen las dos transacciones en la mempool mediante el comando bitcoin-cli getrawmempool"

        bitcoin-cli getrawmempool | jq

echo -e "*************************************************************"
echo -e "9. Aumenta la tarifa de la transacción parent utilizando RBF."
echo -e "*************************************************************\n"

txparentrbf=$(bitcoin-cli -named createrawtransaction inputs='''[ { "txid": "'${txid_miner[0]}'", "vout": '${vout_miner[0]}', "sequence": 1 }, { "txid": "'${txid_miner[1]}'", "vout": '${vout_miner[1]}', "sequence": 1 } ]''' outputs='''[ { "'$envio_trader'": 70 }, { "'$cambio_miner'": 29.9999 }] ''')

echo -e "Transaccion en crudo: $txparentrbf \n"

        bitcoin-cli decoderawtransaction $txparentrbf | jq -r '.vout | .[]'

echo -e "*****************************************************"
echo -e "10. Firma y transmite la nueva transacción principal."
echo -e "*****************************************************\n"

        txparentrbffirmada=$(bitcoin-cli -rpcwallet=Miner signrawtransactionwithwallet $txparentrbf|jq -r .hex)
        txidparentrbf=$(bitcoin-cli sendrawtransaction $txparentrbffirmada)

echo -e "ID de transaccion parent:  $txidparentrbf \n"

echo -e "*******************************************************************************************"
echo -e "11. Realiza otra consulta getmempoolentry para la transacción child y muestra el resultado."
echo -e "*******************************************************************************************\n"

echo "bitcoin-cli getrawmempool"
                bitcoin-cli getrawmempool | jq
                echo -e "bitcoin-cli getmempoolentry $txidchild "
                bitcoin-cli getmempoolentry $txidchild

echo -e "****************************************************************************************************"
echo -e "12. Imprime una explicación en la terminal de lo que cambió en los dos resultados de getmempoolentry" 
echo -e "    para las transacciones child y por qué."
echo -e "****************************************************************************************************\n"

echo -e "Al inicio del ejercicio el ID de la transacción PARENT era $txidparent"
echo -e "Cuando creamos la nueva transacción PARENT, usando los mismos UTXOS pero aplicándole RBF, se anula la primera transacción PARENT"
echo -e "El ID de la nueva transacción es  $txidparentrbf."
echo -e "Y al anularse la primera transacción PARENT, la transacción child asociada desaparece y su TXID  $txidchild ya no se encuentra en la  mempool"
