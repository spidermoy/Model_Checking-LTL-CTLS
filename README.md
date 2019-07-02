# Simple and Efficient On-the-Fly Model Checking for LTL and CTL★

_While simulation and testing explore some of the possible behaviors and scenarios of the system, leaving open the question of whether the unexplored trajectories may contain the fatal bug, formal verification conducts an exhaustive exploration of all possible behaviors._
─Clarke, Grumberg & Peled


_To me, mathematics, computer science, and the arts are insanely related. They’re all creative expressions._
─Sebastian Thrun


_Haskell is faster than C++, more concise than Perl, more regular than Python, more flexible than Ruby, more typeful than C#, more robust than Java, and has absolutely nothing in common with PHP._
─Audrey Tang

This repository contains my work for obtain my computer scientist master degree.


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
     
     donde *num_vars* = número de variables del modelo y *length_forms* = la lóngitud de las fórmulas.

    * Para correr _n_ experimentos LTL de forma automática:
	    
      ./Main tabla _n_ LTL

    * Para correr _n_ experimentos CTL de forma automática:
	    
      ./Main tabla _n_ CTL
    
    * Para recibir como entrada un archivo de NuSMV:
    
      ./Main input *filePath*
      
      Un ejemplo del formato admitido por el verificador es:
      
      ________________________________________________________
      
      MODULE main
      
      VAR
      
      
      p: boolean;
      
      q: boolean;
      
      r: boolean;
      
      DEFINE
      
      
      s0:=  p &  q & !r;
      
      s1:= !p &  q &  r;
      
      s2:= !p & !q &  r;
      
      INIT
      
      
      s0 | s1;
      
      TRANS
      
      
      (s0 & next(s1|s2))
      
      | (s1 & next(s0|s2)) 
      
      | (s2 & next(s2)) 
      
      LTLSPEC  
      
      G !(p&r)
      
      LTLSPEC  
      
      (G F p) -> (G F r)
      
      CTLSPEC
      
      AX AF q
      
      ________________________________________________________

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
* **ParserForms**: Para traducir fórmulas LTL y CTL a fórmulas compatibles con NuSMV. 
* **ParserNuXmv**: Para transformar una estructura de Kripke y varias fórmulas LTL o CTL en un módulo para NuSMV.
* **Exp_LTL**: Para generar experimentos LTL.
* **Exp_CTL**: Para generar experimentos CTL.
* **InputNuSMV**: Para convertir un archivo NuSMV a uno compatible con los verificadores *mcALTL* y *mcCTLS*. Este módulo funciona gracias al parser realizado por [Henning Günther](https://github.com/hguenther/language-nusmv).


* **Main**: El módulo principal donde se corre el proyecto.



