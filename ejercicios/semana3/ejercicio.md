
# Enunciado del Problema

Las transacciones multisig son un aspecto fundamental de la "criptografía Bitcoin compleja" que permite la copropiedad de UTXOs de Bitcoin. Juegan un papel crucial en las soluciones de custodia conjunta para los protocolos de la Capa 2 (L2).

Los protocolos L2 comúnmente comienzan estableciendo una transacción de financiamiento multisig entre las partes involucradas. Por ejemplo, en Lightning, ambas partes pueden financiar conjuntamente la transacción antes de llevar a cabo sus transacciones relámpago. Al cerrar el canal, pueden liquidar el multisig para reclamar sus respectivas partes.

En este ejercicio, nuestro objetivo es simular una transferencia básica de acciones multisig entre dos participantes, Alice y Bob.

## Escribe un script de bash para:

#### Configurar Multisig
1. Crear tres monederos: `Miner`, `Alice` y `Bob`. Es importante usar billeteras del tipo *legacy*, ya que sino lo hacemos nos encontraremos con problemas al usar la opción de bitcoin-cli addmultisigaddress.
2. Fondear los monederos generando algunos bloques para `Miner` y enviando algunas monedas a `Alice` y `Bob`.
3. Crear una dirección Multisig 2-de-2 combinando las claves públicas de `Alice` y `Bob`.
4. Crear una Transacción Bitcoin Parcialmente Firmada (PSBT) para financiar la dirección multisig con 20 BTC, tomando 10 BTC de Alice y 10 BTC de Bob, y proporcionando el cambio correcto a cada uno de ellos.
5. Confirmar el saldo mediante la minería de algunos bloques adicionales.
6. Imprimir los saldos finales de `Alice` y `Bob`.
   
#### Liquidar Multisig
1. Crear una PSBT para gastar fondos del multisig, asegurando que se distribuyan igualmente 10 BTC entre `Alice` y `Bob` después de tener en cuenta las tarifas.
2. Firmar la PSBT por `Alice`.
3. Firmar la PSBT por `Bob`.
4. Extraer y transmitir la transacción completamente firmada.
5. Imprimir los saldos finales de `Alice` y `Bob`.

## Entrega

La carpeta de soluciones de esta semana se encuentra aquí: carpeta de soluciones.
Crea una solicitud de extracción para agregar un nuevo archivo a la carpeta con el nombre <tu-nombre-en-Discord>.sh.
Este archivo debe contener tu script de bash que resuelve todo el ejercicio.
Es obligatorio que se reflejen los pasos del ejercicio, pero siéntete libre de agregar tus propias características de scripting.

## Recursos

- Ejemplos útiles de scripts de bash: [https://linuxhint.com/30_bash_script_examples/](https://linuxhint.com/30_bash_script_examples/)
- Más sobre la Descarga Inicial de Bloques: [https://www.baeldung.com/linux/jq-command-json](https://www.baeldung.com/linux/jq-command-json)
- Ejemplos útiles de `jq`:  [https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/](https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/)
- Cómo crear una solicitud de colaboración en Github a través del navegador web: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)

======================================================================================================

# Problem Statement

Multisig transactions are a fundamental aspect of "complex Bitcoin scripting," enabling co-ownership of Bitcoin UTXOs. They play a crucial role in co-custody solutions for Layer 2 (L2) protocols.

L2 protocols commonly initiate by establishing a multisig funding transaction among involved parties. For instance, in Lightning, both parties may co-fund the transaction before conducting their lightning transactions. Upon closing the channel, they can settle the multisig to reclaim their respective shares.

In this exercise, we aim to simulate a basic multisig share transfer between two participants, Alice and Bob.

### Write a bash script to:

#### Setup Multisig

1. Create three wallets: `Miner`, `Alice`, and `Bob`.
2. Fund the wallets by generating some blocks for `Miner` and sending some coins to `Alice` and `Bob`.
3. Create a 2-of-2 Multisig address by combining public keys from `Alice` and `Bob`.
4. Create a Partially Signed Bitcoin Transaction (PSBT) to fund the multisig address with 20 BTC, taking 10 BTC each from `Alice` and `Bob`, and providing correct change back to each of them.
5. Confirm the balance by mining a few more blocks.
6. Print the final balances of `Alice` and `Bob`.

#### Settle Multisig

1. Create a PSBT to spend funds from the multisig, ensuring 10 BTC is equally distributed back between `Alice` and `Bob` after accounting for fees.
2. Sign the PSBT by `Alice`.
3. Sign the PSBT by `Bob`.
4. Extract and broadcast the fully signed transaction.
5. Print the final balances of `Alice` and `Bob`.

## Submission

- Create a bash script with your solution for the entire exercise.
- Save the script in the provided solution folder with the name `<your-discord-name>.sh`.
- Create a pull request to add the new file to the solution folder.
- The script must include all the exercise steps, but you can also add your own scripting improvements or enhancements.

## Resources

- Useful bash script examples: [https://linuxhint.com/30_bash_script_examples/](https://linuxhint.com/30_bash_script_examples/)
- Useful `jq` examples: [https://www.baeldung.com/linux/jq-command-json](https://www.baeldung.com/linux/jq-command-json)
- Use `jq` to create JSON: [https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/](https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/)
- Creating a pull request via a web browser: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
