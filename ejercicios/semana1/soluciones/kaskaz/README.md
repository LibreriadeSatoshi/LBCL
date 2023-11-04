# Ejercicios Semana 1

He dividido el ejercicio en varios scripts, separando compilación, instalación a partir de binarios directamente, un script que define funciones que utilizo en otro scripts, uno de minado y otro de transacciones.

Todos los scripts se ejecutan como usuario plano (sin sudo). Los que necesitan permisos de administrador solicitarán la contraseña al ejecutarse.

## Compilación

El script `01_compile_bitcoin.sh` descarga el código fuente de bitcoin-core, comprueba su suma de verificación y la firma de los desarrolladores, realiza la compilación (incluyendo bitcoin-qt), realiza los tests de comprobación, crea un archivo .tar.gz conteniendo exclusivamente los binarios y seguidamente borra la carpeta de código fuente y los archivos de firma.

Para la compilación no he incluido la versión legacy de Berkeley DB, he decidido compilar con la que instala el gestor de paquetes de Ubuntu ya que realmente no voy a utilizar la versión compilada para los ejercicios, sino los binarios descargados del sitio. Esta compilación sólo la hice para aprender. Por eso creo un archivo comprimido pero no instalo el software.

NOTA: La ejecución dura mucho tiempo porque se realizan también los tests extendidos.

## Instalación desde binarios

Archivo `02_install_from_binaries.sh`. Esta es la versión de bitcoin-core que voy a usar para los ejercicios. Descarga los binarios y los archivos de suma de verificación y firma, y los comprueba. Seguidamente extrae los binarios y los instala, borra los archivos descargados, crea el directorio de datos y el archivo de configuración para regtest.

## Definición de funciones

El archivo `create_address_function.sh` no realiza ninguna acción. Sólo define la función `create_address`, que utilizo en los dos siguientes scripts por lo que he decidido definirla en un sólo archivo.

Otras funciones están en sus archivos correspondientes pues sólo se usan en ese archivo.

## Creación de Wallets y minado

El archivo `03_wallets_mining.sh` crea las carteras solicitadas por el ejercicio y mina bloques hasta que se confirma un saldo positivo en la cartera "Miner".

## Transferencia de fondos

El archivo `04_transaction.sh` envía saldo del wallet "Miner" a una nueva dirección de la wallet "Trader" y obtiene los detalles de la transacción cuando todavía está en la mempool y cuando ya se ha incorporado a un bloque, mostrándolos por consola.