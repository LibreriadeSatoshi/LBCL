# Presentación
Discutir sobre las siguientes preguntas
* ¿Quienes somos?
* ¿Porque estamos aquí?
* ¿Porque debemos involucrarnos desde el primer momento y colaborar?

## Objetivos
Comentar objetivos que es lo que aprenderán
* Conocer a bajo nivel como funcionan las transacciones de bitcoin
* Crear todo tipo de transacciones (menos taproot) desde línea de comandos
* Practicar con PSBTs, RBF, CPFP, TIMELOCKs, transaciones multifirma
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

## Planificación
La planificación de las clases prácticas será la siguiente:
* Semana0: Sesión introductoria a las prácticas donde se mostrará la forma de trabajar y se resolverán dudas
* Semana1: Descarga, verificación e instalación de bitcoin-core. Arrancar el nodo en modo regtest, crear billeteras y hacer transacciones
* Semana2: Experimentar con los mecanismos Replace-By-Fee (RBF) y Child-Pays-for-Parent (CPFP)
* Semana3: Transacciones multisig, como bloquear utxo en una multifirma y como posteriormente gastar los fondos.
* Semana4: Creación de transacciones con Timelocks
Si alguien acaba la práctica semanal y desea profundizar más, tengo en mente una serie de ejercicios adicionales.

## Funcionamiento
* La semana previa se procederá a la lectura de la práctica
* Durante la semana los alumnos realizarán la práctica y la subirán a github
* En la siguiente sesión práctica se presentará la solución al ejercicio y se resolverán las dudas. Y por último se presentará la siguiente práctica

## Herramientas necesarias
Disponer de un entorno de trabajo lo más estándard posible. La recomendación es un Ubuntu 22.04 LTS con los siguientes paquetes instalados: 

```
apt-get install -y bc jq autoconf file gcc libc-dev make g++ pkgconf re2c git libtool automake gcc xxd
```

## Conoce tu nodo
Esa es nuestra principal misión durante el curso. Bitcoin-core tiene dos piezas básicas que serán el objetivo del curso:
* bitcoind: es el programa que se ejecuta en segundo plano y se encarga de la recepción, propagación, validación de transacciones, la gestión de la cadena de bloques y la comunicación con otros nodos de la red Bitcoin
* bitcoin-cli: es un cliente que permite interactuar con nuestro nodo (bitcoind) desde línea de comandos.

Comentar las diferencias entre:

```
bitcoin-cli help
bitcoin-cli --help
```

Listar el contenido de la ayuda en línea de bitcoind:
```
bitcoind --help  
```

Recalcar la importancia de conocer a bajo nivel las diferentes opciones de los comandos anteriores. Tratar de evitar que los arboles nos inpidan ver el bosque. Durante el curso comentaremos cosas muy interesantes, auténticos endless rabbit holes, pero hay que tener presente cual es el objetivo y estar lo más focalizado posible para aprovechar al máximo el curso.

## Presentar primera práctica
Veámos nuestro [primer ejercicio](../semana1/ejercicio.md)

## Dudas preguntas


## Herramientas útiles
Estas herramientas pueden ser muy útiles durante el curso. No son necesarias, e instalarlas puede llevar tiempo a usuarios no experimentados.

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

Sparrow es una herramienta muy útil para examinar transacciones de forma visual. Permite importar transacciones en hexadecimal creadas con bitcoin-cli, visualizarlas, analizarlas a bajo nivel y transmitirlas a la red Bitcoin.

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

Esperamos unos minutos a descargar y crear los containers. Una vez finalizado, podremos conectarnos a nuestro propio [mempool.space](http://localhost:1080) bitcoin regtest explorer por el puerto 1080 de nuestro localhost.
