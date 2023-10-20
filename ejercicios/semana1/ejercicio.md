# Enunciado del Problema

Los pasos iniciales de cualquier software de nodo automatizado (Umbrel, MyNode, Raspibltiz, etc.) consisten en descargar los binarios de Bitcoin, verificar las firmas, instalarlos en ubicaciones correctas, proporcionar acceso específico al usuario y luego iniciar el nodo.

Luego, el nodo entrará en la fase de Descarga Inicial de Bloques (IBD, por sus siglas en inglés), donde descargará y validará todo el blockchain de Bitcoin. Una vez que se completa el IBD, iniciará una billetera y el usuario podrá comenzar a realizar transacciones de Bitcoin con el nodo (a través de la interfaz del nodo o conectando billeteras móviles al nodo).

El siguiente ejercicio es una versión simplificada de este proceso a través de un script de bash.

No será necesario realizar el IBD, ya que estaremos utilizando `regtest`, donde podemos crear nuestros propios bloques de juguete con transacciones de juguete.

### Escribe un script de bash para:
**--Configuración**

- Descargar los binarios principales de Bitcoin desde el sitio web de Bitcoin Core https://bitcoincore.org/.
- Utilizar los hashes y la firma descargados para verificar que los binarios sean correctos. Imprimir un mensaje en la terminal: "Verificación exitosa de la firma binaria".
- Copiar los binarios descargados a la carpeta `/usr/local/bin/`.

**--Iniciar**

- Crear un archivo `bitcoin.conf` en el directorio de datos `/home/<nombre-de-usuario>/.bitcoin/`. Crear el directorio si no existe. Y agregar las siguientes líneas al archivo:

```
regtest=1
fallbackfee=0.0001
server=1
txindex=1
```
- Iniciar `bitcoind`.
- Crear dos billeteras llamadas `Miner` y `Trader`.
- Generar una dirección desde la billetera `Miner` con una etiqueta "Recompensa de Minería".
- Extraer nuevos bloques a esta dirección hasta obtener un saldo de billetera positivo. (utilizar `generatetoaddress`) (cuántos bloques se necesitaron para obtener un saldo positivo)
- Escribir un breve comentario que describa por qué el saldo de la billetera para las recompensas en bloque se comporta de esa manera.
- Imprimir el saldo de la billetera `Miner`.
  
**--Uso**

- Crear una dirección receptora con la etiqueta "Recibido" desde la billetera `Trader`.
- Enviar una transacción que pague 20 BTC desde la billetera `Miner` a la billetera del `Trader`.
- Obtener la transacción no confirmada desde el "mempool" del nodo y mostrar el resultado. (pista: `bitcoin-cli help` para encontrar la lista de todos los comandos, busca `getmempoolentry`).
- Confirmar la transacción creando 1 bloque adicional.
- Obtener los siguientes detalles de la transacción y mostrarlos en la terminal:

`txid:` `<ID de la transacción>`
`<De, Cantidad>`: `<Dirección del Miner>`, `Cantidad de entrada.`
`<Enviar, Cantidad>`: `<Dirección del Trader>`, `Cantidad enviada.`
`<Cambio, Cantidad>`: `<Dirección del Miner>`, `Cantidad de cambio.`
`Comisiones`: `Cantidad pagada en comisiones.`
`Bloque`: `Altura del bloque en el que se confirmó la transacción.`
`Saldo de Miner`: `Saldo de la billetera Miner después de la transacción.`
`Saldo de Trader`: `Saldo de la billetera Trader después de la transacción.`

**--Sugerencias**

- Para descargar los binarios más recientes para Linux x86-64 a través de la línea de comandos: `wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz`.
- Busca en Google comandos de terminal para una tarea específica si no los tienes a mano. Ejemplo: "cómo extraer una carpeta zip a través de la terminal de Linux", "cómo copiar archivos a otro directorio a través de la terminal de Linux", etc.
- Utiliza la herramienta `jq` para obtener datos específicos de objetos JSON devueltos por `bitcoin-cli`.

**--Entrega**

La carpeta de soluciones de esta semana se encuentra aquí: carpeta de soluciones.
Crea una solicitud de extracción para agregar un nuevo archivo a la carpeta con el nombre <tu-nombre-en-Discord>.sh.
Este archivo debe contener tu script de bash que resuelve todo el ejercicio.
Es obligatorio que se reflejen los pasos del ejercicio, pero siéntete libre de agregar tus propias características de scripting.

**--Recursos**

- Ejemplos útiles de scripts de bash: [https://linuxhint.com/30_bash_script_examples/](https://linuxhint.com/30_bash_script_examples/)
- Más sobre la Descarga Inicial de Bloques: [https://www.baeldung.com/linux/jq-command-json](https://www.baeldung.com/linux/jq-command-json)
- Ejemplos útiles de `jq`:  [https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/](https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/)
- Cómo crear una solicitud de colaboración en Github a través del navegador web: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)

===================================================================================================================================================================================

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
