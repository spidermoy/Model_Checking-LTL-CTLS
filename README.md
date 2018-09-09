# Verificación de modelos LTL y CTL★

Este repositorio contiene la implementación de los algoritmos propuestos en mi tesis de maestría _«Un verificador sencillo y eficiente  para la lógica LTL y CTL★ escrito en Haskell»_.

## Requisitos:

* [GHC (The Glasgow Haskell Compiler)](https://www.haskell.org/ghc/)
* [Haskell Cabal](https://www.haskell.org/cabal/)
* Una vez instalado Cabal es necesario instalar la biblioteca *Random* tecleando:

     cabal install random    
* [NuSMV](http://nusmv.fbk.eu/) (no es necesario instalarlo si no desea comparar desempeño).

## Modo de uso

1. Se compila el código tecleando: ghc -O2 Main.hs
2. El programa puede correrse de la siguiente manera:

   * Para correr un experimento aleatorio LTL:
   
     ./Main random LTL *num_vars* *length_forms*

   * Para correr un experimento aleatorio LTL y comparar los resultados con NuSMV:
	
     ./Main random nusmv LTL *num_vars* *length_forms*

   * Para correr un experimento aleatorio CTL:
	
     ./Main random CTL *num_vars* *length_forms*
     
   * Para correr un experimento aleatorio CTL y comparar los resultados con NuSMV:
	
     ./Main random nusmv CTL *num_vars* *length_forms*

   * Para correr un experimento LTL con semillas generadoras:
	
     ./Main seeds _ranInit ranNumInit ranKS ranF_ LTL *num_vars* *length_forms*

   * Para correr un experimento LTL con semillas generadoras y comparar los resultados con NuSMV:
	
     ./Main seeds _ranInit ranNumInit ranKS ranF_ nusmv LTL *num_vars* *length_forms*

   * Para correr un experimento CTL con semillas generadoras:
	
     ./Main seeds _ranInit ranNumInit ranKS ranF_ CTL *num_vars* *length_forms*

   * Para correr un experimento CTL con semillas generadoras y comparar los resultados con NuSMV:

     ./Main seeds _ranInit ranNumInit ranKS ranF_ nusmv CTL *num_vars* *length_forms*

    * Para correr _n_ experimentos LTL de forma automática:
	    
      ./Main tabla _n_ LTL

    * Para correr _n_ experimentos CTL de forma automática:
	    
      ./Main tabla _n_ CTL
    
    * Para recibir como entrada un archivo de NuSMV:
    
      ./Main input *filePath*
      

donde *num_vars* = número de variables del modelo y *length_forms* = la lóngitud de las fórmulas.

Algunos ejemplos son:

* ./Main random LTL 4 3

* ./Main seeds 100 76 4 0 nusmv CTL 10 2

* ./Main tabla 5 CTL



## Módulos 

El código está separado en módulos de la siguiente manera:
* **Core**:
Contiene todo lo necesario para implementar los verificadores de modelos: la definición de estructura de Kripke, fórmulas de trayectoria, fórmulas de estado, entre otras. También contiene a los verificadores *mcALTL* y *mcCTLS* que sirven para hacer verificación LTL y CTL★, respectivamente. 

* **RandomForms**: Para generar fórmulas LTL y CTL aleatorias.
* **RandomKS**: Para generar estructuras de Kripke de forma aleatoria.
* **Binarios**: Sirve como subrutina para crear modelos aleatorios compatibles con NuSMV.
* **ParserForms**: Para traducir fórmulas LTL y CTL a fórmulas compatibles con NuSMV. 
* **ParserNuXmv**: Para transformar una estructura de Kripke y varias fórmulas LTL o CTL en un módulo para NuSMV.
* **Exp_LTL**: Para generar experimentos LTL.
* **Exp_CTL**: Para generar experimentos CTL.
* **InputNuSMV**: El módulo para convertir un archivo NuSMV a uno compatible con los verificadores *mcALTL* y *mcCTL★*.
* **Main**: El módulo principal donde se corre el proyecto.



