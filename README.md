# Simple and Efficient On-the-Fly Model Checking for LTL, CTL and CTL★

_While simulation and testing explore some of the possible behaviors and scenarios of the system, leaving open the question of whether the unexplored trajectories may contain the fatal bug, formal verification conducts an exhaustive exploration of all possible behaviors._

─Clarke, Grumberg & Peled


_To me, mathematics, computer science, and the arts are insanely related. They’re all creative expressions._

─Sebastian Thrun


_Haskell is faster than C++, more concise than Perl, more regular than Python, more flexible than Ruby, more typeful than C#, more robust than Java, and has absolutely nothing in common with PHP._

─Audrey Tang

This repository contains my work for obtain my computer scientist master degree: a simple model checker
for temporal logics written in [Haskell](https://www.haskell.org/).
This work simplifies and improves Girish Bhat, Rance Cleaveland and Orna Grumberg work.
See [Efficient On-the-Fly Model Checking for CTL★](https://www.semanticscholar.org/paper/Eecient-On-the-fly-Model-Checking-for-Ctl-Bhat-Cleaveland/e7dbc6e9ff14c98d61af98247e79a3b2058cbfff) for more details.
([This repository](https://github.com/spidermoy/OnTheFly_ModelChecking) contains the original implementation of Bhat, Cleaveland and Grumberg algorithm.)

In summary, this repository contains a model verifier for LTL temporal logic, which, does not use Büchi's 
Automatons or Strongly Connected Components, is only based on formal semantics.
This verifier extends naturally to the CTL★ temporal logic (and thus, to the CTL logic).


## Requirements:

* [GHC (The Glasgow Haskell Compiler)](https://www.haskell.org/ghc/)
* [Haskell Cabal](https://www.haskell.org/cabal/)
* random library (`cabal install random`)
* [nuXmv](https://nuxmv.fbk.eu/)

## How to use:

1. Copile the project:

`ghc -O2 --make -threaded Main.hs`

2. How to use it:

Let _n_ the number of variables, and _m_ the depth of the formulas of the experiments. Both
_n_ and _m_ are positive integers. 

   * Run a random LTL experiment:

    ./Main random LTL n m


