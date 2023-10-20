# LBCL Cohort Ejercicio Semana 2

## Enunciado del Problema

Ahora que tenemos un nodo de Bitcoin en funcionamiento, con una billetera conectada, en este ejercicio realizaremos algunos flujos de trabajo básicos de uso de billeteras de Bitcoin utilizando scripts de bash y la interfaz de línea de comandos `bitcoin-cli`. Nos enfocaremos en aumentar la tarifa utilizando los mecanismos de Replace-By-Fee (RBF) y Child-Pays-for-Parent (CPFP).

A menudo, las billeteras necesitan aumentar las tarifas en momentos de altas tasas de tarifas. Hay dos formas de aumentar las tarifas, RBF y CPFP. Ambos utilizan mecanismos diferentes para aumentar la tarifa, pero no pueden usarse juntos. Intentar RBF una transacción invalidaría la CPFP, ya que la transacción secundaria no puede ser válida si su transacción principal se elimina del "mempool".

El siguiente ejercicio intenta demostrar esa situación.

## Tarea

Escribe un script de bash para:

1) Crear dos billeteras llamadas `Miner` y `Trader`.
2) Fondear la billetera `Miner` con al menos el equivalente a 3 recompensas en bloque en satoshis (Saldo inicial: 150 BTC).
3) Crear una transacción desde `Miner` a `Trader` con la siguiente estructura (llamémosla la `parent`):
	- Entrada[0]: Recompensa en bloque de 50 BTC.
	- Entrada[1]: Recompensa en bloque de 50 BTC.
	- Salida[0]: 70 BTC para `Trader`.
	- Salida[1]: 29.99999 BTC de cambio para `Miner`.
	- **Activar RBF** (Habilitar RBF para la transacción).
4) Firmar y transmitir la `parent`, pero no la confirmes aún.
5) Realizar consultas al "mempool" del nodo para obtener los detalles de la `parent`. Utiliza los detalles para crear una variable JSON con la siguiente estructura:

```json
{
  "input": [
	{
  	"txid": "<Trader's Txid>",
  	"vout": "<num>"
	},
	{
  	"txid": "<Miner's Txid>",
  	"vout": "<num>"
	}
  ],
  "output": [
	{
  	"script_pubkey": "<Miner's script_pubkey>",
  	"amount": "<miner's amount>"
	},
	{
  	"script_pubkey": "<Trader's script pubkey>",
  	"amount": "<trader's amount>"
	}
  ],
  "Fees": "<num>",
  "Weight": "<num>" (weight of the tx in vbytes)
}
```
- Utiliza `bitcoin-cli` help para obtener todos los comandos específicos de categoría (billetera, mempool, cadena, etc.).
- Usa `bitcoin-cli help <nombre-del-comando>` para obtener información de uso de comandos específicos.
- Utiliza `jq` para obtener datos de la salida de `bitcoin-cli` en variables de bash y utiliza nuevamente `jq` para crear tu JSON a partir de las variables.
- Es posible que debas realizar varias llamadas a la CLI para obtener todos los detalles.
6) Imprime el JSON anterior en la terminal.
7) Crea una nueva transmisión que gaste la transacción anterior (`parent`). Llamémosla transacción `child`.
	- Entrada[0]: Salida de `Miner` de la transacción `parent`.
	- Salida[0]: Nueva dirección de `Miner`. 29.99998 BTC.
8) Realiza una consulta `getmempoolentry` para la tranasacción `child` y muestra la salida.
9) Ahora, aumenta la tarifa de la transacción `parent` utilizando RBF. No uses `bitcoin-cli bumpfee`, en su lugar, crea manualmente una transacción conflictiva que tenga las mismas entradas que la transacción `parent` pero salidas diferentes, ajustando sus valores para aumentar la tarifa de la transacción `parent` en 10,000 satoshis.
10) Firma y transmite la nueva transacción principal.
11) Realiza otra consulta `getmempoolentry` para la transacción `child` y muestra el resultado.
12) Imprime una explicación en la terminal de lo que cambió en los dos resultados de `getmempoolentry` para las transacciones `child` y por qué.

## Entrega

- Crea un script de bash con tu solución para todo el ejercicio.
- Guarda el script en la carpeta de soluciones proporcionada con el nombre `<tu-nombre-en-Discord>.sh`
- Crea una solicitud de pull para agregar el nuevo archivo a la carpeta de soluciones.
- El script debe incluir todos los pasos del ejercicio, pero también puedes agregar mejoras o funcionalidades adicionales a tu script.

**--Recursos**

- Ejemplos útiles de scripts de bash: `https://linuxhint.com/30_bash_script_examples/`.
- Más sobre la Descarga Inicial de Bloques: `https://bitcoin.org/en/full-node#initial-block-downloadibd`.
- Ejemplos útiles de `jq`: `https://www.baeldung.com/linux/jq-command-json`.
- Cómo crear una solicitud de colaboración en Github a través del navegador web: `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request`.

  
=============================================================================================================================


# LBCL Cohort Exercise Week 2

## Problem Statement
Now that we have a running Bitcoin node, with a wallet connected, in this exercise, we will perform some basic Bitcoin wallet usage workflows using bash scripting and the `bitcoin-cli` command-line interface. We will focus on fee bumping using Replace-By-Fee (RBF) and Child-Pays-for-Parent (CPFP) mechanisms.

Wallets often need to fee-bump transactions in times of high fee-rate markets. There are two ways of fee bumping, RBF and CPFP. They both use different mechanisms for bumping the fee, but they cannot be used together. Trying to RBF a transaction would invalidate the CPFP, because the child transaction cannot be valid if its parent is removed from the mempool.

The following exercise attempts to demo that situation.

## Task

Write a bash script to:

1. Create two wallets named `Miner` and `Trader`.
2. Fund the `Miner` wallet with at least 3 block rewards worth of satoshis (Starting balance: 150 BTC).
3. Craft a transaction from `Miner` to `Trader` with the following structure (let's call it the `Parent` transaction):
   - Input[0]: 50 BTC block reward.
   - Input[1]: 50 BTC block reward.
   - Output[0]: 70 BTC to `Trader`.
   - Output[1]: 29.99999 BTC change-back to `Miner`.
   - **Signal for RBF** (Enable RBF for the transaction).
4. Sign and broadcast the `Parent` transaction but do not mine it yet.
5. Make queries to the node's mempool to get the `Parent` transaction details. Use the details to craft a JSON variable with the following structure:

```json
{
  "input": [
	{
  	"txid": "<Trader's Txid>",
  	"vout": "<num>"
	},
	{
  	"txid": "<Miner's Txid>",
  	"vout": "<num>"
	}
  ],
  "output": [
	{
  	"script_pubkey": "<Miner's script_pubkey>",
  	"amount": "<miner's amount>"
	},
	{
  	"script_pubkey": "<Trader's script pubkey>",
  	"amount": "<trader's amount>"
	}
  ],
  "Fees": "<num>",
  "Weight": "<num>" (weight of the tx in vbytes)
}
```

- Use `bitcoin-cli help` to get all the category-specific commands (wallet, mempool, chain, etc.).
- Use `bitcoin-cli help <command-name>` to get usage information of specific commands.
- Use `jq` to fetch data from `bitcoin-cli` output into bash variables and use `jq` again to craft your JSON from the variables.
- You might have to make multiple CLI calls to get all the details.

6. Print the above JSON in the terminal.
7. Create a broadcast new transaction that spends from the above transaction (the `Parent`). Let's call it the `Child` transaction.
   - Input[0]: `Miner`'s output of the `Parent` transaction.
   - Output[0]: `Miner`'s new address. 29.99998 BTC.
8. Make a `getmempoolentry` query for the `Child` transaction and print the output.

9. Now, fee bump the `Parent` transaction using RBF. Do not use `bitcoin-cli bumpfee`, instead hand-craft a conflicting transaction, that has the same inputs as the `Parent` but different outputs, adjusting their values to bump the fee of `Parent` by 10,000 satoshis.
10. Sign and broadcast the The new Parent transaction.
11. Make another `getmempoolentry` query for the `Child` transaction and print the result.
12. Print an explanation in the terminal of what changed in the two `getmempoolentry` results for the `Child` transactions, and why?

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
