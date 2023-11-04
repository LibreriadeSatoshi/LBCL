#!/bin/bash

# Actualiza los paquetes del sistema
sudo apt update
sudo apt upgrade -y

# Instala las dependencias requeridas por bitcoin, tanto para la ejecución como la compilación
sudo apt install net-tools git build-essential haveged gnupg dirmngr xxd autoconf autotools-dev automake pkg-config clang libboost-dev libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-test-dev libboost-thread-dev libevent-dev libnatpmp-dev libminiupnpc-dev libsqlite3-dev libtool bsdmainutils python3 libssl-dev libzmq3-dev libprotobuf-dev protobuf-compiler ccache -y
# Vamos a utilizar la última versión de Berkeley DB ya que no pretendemos copiar el 
# archivo binario wallet.dat a otro nodo
sudo apt install  libdb-dev -y
# Instalamos las dependencias de la interfaz gráfica para incluirla en la compilación
sudo apt-get install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools qtwayland5 libqrencode-dev -y

# Versión a compilar
export BITCOIN="bitcoin-core-25.1"
export BITCOINPLAIN=`echo $BITCOIN | sed 's/bitcoin-core/bitcoin/'`

# Descargamos el código fuente de Bitcoin Core
wget https://bitcoincore.org/bin/$BITCOIN/$BITCOINPLAIN.tar.gz
# Y los archivos con las sumas de verificación y las firmas PGP
wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS.asc
wget https://bitcoincore.org/bin/$BITCOIN/SHA256SUMS

# Clonamos el repositorio con las claves públicas de los autores del proyecto
git clone https://github.com/bitcoin-core/guix.sigs.git
for file in ./guix.sigs/builder-keys/*.gpg; do gpg --import "$file"; done

# Verificamos la autenticidad del archivo SHA256SUMS 
export SHASIG=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature"`
export SHACOUNT=`gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep "Good signature" | wc -l`

if [[ "$SHASIG" ]]
then
    echo "$0 - Verificación de firma correcta: Encontradas $SHACOUNT firmas correctas."
    echo "$SHASIG"
else
    (>&2 echo "$0 - Error de verificación de firmas: No se ha podido verificar el archivo SHA256SUMS")
fi

# Busca en el directorio actual los archivos indicados en SHA256SUMS y 
# comprueba sus sumas de verificación
export SHACHECK=`sha256sum -c --ignore-missing < SHA256SUMS 2>&1 | grep "OK"`

if [ "$SHACHECK" ]
then
   echo "$0 - Verificación exitosa de la firma binaria. Comprobados los archivos: $SHACHECK"
else
    (>&2 echo "$0 - Verificación de SHA incorrecta!")
fi

# Extrae el código fuente
tar xzf $BITCOINPLAIN.tar.gz
cd $BITCOINPLAIN

# Compila Bitcoin Core
./autogen.sh
./configure
make -j 4

# Ejecuta los tests de verificación
make check
./test/functional/test_runner.py --extended

# Extrae los binarios compilados a un archivo tar
tar --transform 's/.*\///g' -czf ../$BITCOINPLAIN-compiled.tar.gz ./src/bitcoin-wallet ./src/bitcoin-tx ./src/bitcoin-util ./src/bitcoind ./src/bitcoin-cli ./src/qt/bitcoin-qt

# Borra el código fuente y el resto de archivos descargados
cd ..
rm -fr $BITCOINPLAIN $BITCOINPLAIN.tar.gz guix.sigs SHA256SUMS.asc SHA256SUMS