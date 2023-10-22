# Presentación

## Objetivos
Comentar objetivos que es lo que aprenderan
* Conocer a bajo nivel como funcionan las transacciones de bitcoin
* Crear todo tipo de transacciones (menos taproot) desde linea de comandos
* Practicar con PSBTs, RBF, CPFP, TIMELOCKs, Transaciones multifirma
* Explorar la blockchain desde tu nodo
* Además durante el viaje aprenderás Linux, Bash, JSON, git y espero que muchas cosas más

## Requisitos
Los siguientes conocimientos son necesarios para poder aprovechar el curso al 100%:
* Conocimientos de Linux a nivel medio/avanzado
* Bash scripting
* Transacciones Bitcoin:
  * Cómo funciona una tx de bitcoin
  * Qué es un utxo
  * Conocimientos mínimos sobre como se forjan y minan los bloques
* Trabajar con github. Como crear un [Pull Request documentación oficial](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) pero es más efectivo ver el siguiente [videotutorial](https://www.youtube.com/watch?v=BPns9r76vSI)

## Funcionamiento
* La semana previa se procederá a la lectura de la práctica
* Durante la semana los alumnos realizarán la práctica y la subirán a github
* En la siguiente sesión práctica se presentará la solución al ejercio y se resolverán las dudas. Y por último se presentará la siguiente práctica

## Herramientas necesarias
Disponer de un entorno de trabajo lo más estandard posible. La recomendación es un Ubuntu 22.04 LTS con los siguientes paquetes instalados: 

```
apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
```

## Presentar primera práctica
Veámos nuestro [primer ejercicio](../semana1/ejercicio.md)

## Dudas preguntas


## Herramientas utiles
Estas herramientas pueden ser muy utiles durante el curso. No son necesarias, e instalarlas puede llevar tiempo a usuarios no experimentados.

### Definición de alias 
Podemos definir alias para nuestro comando bitcoin-cli en nuestro .bashrc 
```
alias bt='bitcoin-cli -chain=main -rpcconnect=192.168.0.6 -rpcuser=test -rpcpassword=test321'
alias btr='bitcoin-cli -regtest -rpcuser=test -rpcpassword=test321'
alias btt='bitcoin-cli -testnet -rpcuser=test -rpcpassword=test321 -rpcconnect=192.168.0.5'
```

### Instalar Sparrow wallet
Desde ubuntu:

```
apt-get install sparrow
```

Para arrancar sparrow en modo regtest:

```
/opt/sparrow/bin/Sparrow -n regtest
```

Configurar sparrow para que se conecte a nuestro nodo bitcoin en regtest.

Sparrow es una herramienta muy util para examinar transacciones de forma visual. Permite importar transacciones en hexadecimal creadas con bitcoin-cli, visualizarlas, analizarlas a bajo nivel y broadcastearlas.

### Visualizar nuestra blockchain en regtest (usuarios avanzados)

Requiere tener docker instalado en nuestro entorno de trabajo:
```
apt-get install docker 
```

Clonamos el siguiente repositorio github para descargarnos un 
```
git clone https://github.com/lazysatoshi/docker-btc-regtest-stack
```

Arrancamos el docker stack:

```
cd docker-btc-regtest-stack
docker compose up
```

Esperamos unos minutos a descargar y crear los containers. Una vez finalizado, podremos conectarnos a nuestro propio [mempool.space](https://localhost:1080) bitcoin regtest explorer por el puerto 1080 de nuestro localhost.
