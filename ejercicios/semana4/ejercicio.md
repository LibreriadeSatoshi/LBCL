# Enunciado del Problema

Los timelocks son mecanismos para crear transacciones que están bloqueadas hasta que haya pasado X unidades de tiempo. Estas transacciones no pueden incluirse en el bloque hasta que haya transcurrido el tiempo especificado. Esto puede ser útil para varios tipos de situaciones de flujo de transacciones en las que los fondos están bloqueados de manera segura.
`OP_RETURN` es un código de operación que se puede utilizar para grabar datos aleatorios en una transacción. Esto tiene diversos usos, desde la marca de tiempo hasta los NFT (Tokens No Fungibles) basados en Bitcoin.
En el siguiente ejercicio, pasaremos por un flujo de trabajo en el que un empleado recibe su salario de un empleador, pero solo después de que haya transcurrido cierto tiempo. El empleado también lo celebra y realiza un gasto de `OP_RETURN` para que todo el mundo sepa que ya no está desempleado.

## Escribe un script de bash para:

#### Configurar un contrato Timelock

1. Crea tres monederos: `Miner`, `Empleado` y `Empleador`.
2. Fondea los monederos generando algunos bloques para `Miner` y enviando algunas monedas al `Empleador`.
3. Crea una transacción de salario de 40 BTC, donde el `Empleador` paga al `Empleado`.
4. Agrega un timelock absoluto de 500 bloques para la transacción, es decir, la transacción no puede incluirse en el bloque hasta que se haya minado el bloque 500.
5. Informa en un comentario qué sucede cuando intentas transmitir esta transacción.
6. Mina hasta el bloque 500 y transmite la transacción.
7. Imprime los saldos finales del `Empleado` y `Empleador`.

#### Gastar desde el Timelock
1. Crea una transacción de gasto en la que el `Empleado` gaste los fondos a una nueva dirección de monedero del `Empleado`.
2. Agrega una salida `OP_RETURN` en la transacción de gasto con los datos de cadena `"He recibido mi salario, ahora soy rico"`.
3. Extrae y transmite la transacción completamente firmada.
4. Imprime los saldos finales del `Empleado` y `Empleador`.

## Entrega
- Crea un script de bash con tu solución para todo el ejercicio.
- Guarda el script en la carpeta de soluciones proporcionada con el nombre `<tu-nombre-en-Discord>.sh`
- Crea una solicitud de pull para agregar el nuevo archivo a la carpeta de soluciones.
- El script debe incluir todos los pasos del ejercicio, pero también puedes agregar mejoras o funcionalidades adicionales a tu script.

## Recursos

Ejemplos útiles de scripts de bash: https://linuxhint.com/30_bash_script_examples/
Ejemplos útiles de uso de jq: https://www.baeldung.com/linux/jq-command-json
Usar jq para crear JSON: https://spin.atomicobject.com/2021/06/08/jq-creating-updating-json/
Cómo crear una solicitud de extracción a través de un navegador web: [https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)

===========================================================================================

# Problem Statement

Timelocks are mechanisms to create transactions that are locked until X unit of time. These transactions cannot be included in the block until the said time has passed. This can be useful for various types of transaction workflow situations where funds are locked trustlessly.
`OP_RETURN` is an OP code that can be used to etch random data into a transaction. This has various use, from timestamping to Bitcoin-based NFTs.
In the following exercise, we go through a workflow where an `Employee` is getting paid by an `Employer` but only after a certain time has passed. The employee also exclaims in joy and post a OP_RETURN spend for the whole world to see that he isn't jobless anymore.

## Write a bash script to:

#### Setup a TimeLock contract
1. Create three wallets: `Miner`, `Employee`, and `Employer`.
2. Fund the wallets by generating some blocks for `Miner` and sending some coins to `Employer`.
3. Create a salary transaction of 40 BTC, where the `Employer` pays the `Employee`.
4. Add an absolute timelock of 500 Blocks for the transaction, i.e. the transaction cannot be included in the blockchain until the 500th block is mined.
5. Report in a comment what happens when you try to broadcast this transaction.
6. Mine up to 500th block and broadcast the transaction.
7. Print the final balances of `Employee` and `Employer`.

#### Spend from the TimeLock
1. Create a spending transaction where the `Employee` spends the fund to a new `Employee` wallet address.
2. Add an `OP_RETURN` output in the spending transaction with the string data "I got my salary, I am rich".
3. Extract and broadcast the fully signed transaction.
4. Print the final balances of the `Employee` and `Employer`.

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
