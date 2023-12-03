# Enunciado del Problema

Los timelocks relativos se utilizan para crear bloqueos específicos para una entrada. Utilizando timelocks relativos, una transacción puede estar bloqueada hasta cierto número de bloques desde el bloque en el que se ha minado la entrada a la que se hace referencia.

El ejercicio a continuación demuestra el uso de un timelock relativo.

## Escribe un script de bash para:

#### Configurar un timelock relativo
1. Crear dos billeteras: `Miner`, `Alice`.
2. Fondear las billeteras generando algunos bloques para `Miner` y enviando algunas monedas a `Alice`.
3. Confirmar la transacción y chequar que `Alice` tiene un saldo positivo.
4. Crear una transacción en la que `Alice` pague 10 BTC al `Miner`, pero con un timelock relativo de 10 bloques.
5. Informar en la salida del terminal qué sucede cuando intentas difundir la segunda transacción.

#### Gastar desde el timelock relativo
1. Generar 10 bloques adicionales.
2. Difundir la segunda transacción. Confirmarla generando un bloque más.
3. Informar el saldo de `Alice`.

## Entrega
- Crea un script de bash con tu solución para todo el ejercicio.
- Guarda el script en la carpeta de soluciones proporcionada con el nombre `<tu-nombre-en-Discord>.sh`
- Crea una solicitud de pull para agregar el nuevo archivo a la carpeta de soluciones.
- El script debe incluir todos los pasos del ejercicio, pero también puedes agregar mejoras o funcionalidades adicionales a tu script.

## Recursos

- Ejemplos útiles de scripts de bash: https://linuxhint.com/30_bash_script_examples/
- Ejemplos útiles de uso de jq: https://www.baeldung.com/linux/jq-command-json
- Usar jq para crear JSON: https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/
- Cómo crear una solicitud de extracción a través de un navegador web: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)

===========================================================================================

# Problem Statement

Relative timelocks are used to make input-specific locks. Using relative timelock, a transaction can be locked up to a certain number of blocks since the block in which the input it is referring to has been mined.

The exercise below demonstrates using a relative timelock spend.

## Write a bash script to:

#### Setup a relative timelock

1. Create two wallets: `Miner`, `Alice`.
2. Fund the wallets by generating some blocks for `Miner` and sending some coins to `Alice`.
3. Confirm the transaction and assert that `Alice` has a positive balance.
4. Create a transaction where `Alice` pays 10 BTC back to `Miner`, but with a relative timelock of 10 blocks.
5. Report in the terminal output what happens when you try to broadcast the 2nd transaction.
#### Spend from relative timeLock

1. Generate 10 more blocks.
2. Broadcast the 2nd transaction. Confirm it by generating one more block.
3. Report Balance of `Alice`.

## Submission

- Create a bash script with your solution for the entire exercise.
- Save the script in the provided solution folder with the name `<your-discord-name>.sh`.
- Create a pull request to add the new file to the solution folder.
- The script must include all the exercise steps, but you can also add your own scripting improvements or enhancements.
- The best script of the week will be showcased in the discord `shell-showcase` channel.

## Resources

- Useful bash script examples: [https://linuxhint.com/30_bash_script_examples/](https://linuxhint.com/30_bash_script_examples/)
- Useful `jq` examples: [https://www.baeldung.com/linux/jq-command-json](https://www.baeldung.com/linux/jq-command-json)
- Use `jq` to create JSON: [https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/](https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/)
- Creating a pull request via a web browser: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
