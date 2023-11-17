#!/bin/bash

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
