module RandomKS where
import Core
import Data.List(nub, sort)
import System.Random(mkStdGen, randomR, randomRs)


--Esta función genera un modelo aleatorio con 2^n estados a partir de una lista de semillas.
randomKS::Int->[Int]->KripkeS
randomKS n rs = KS (2^n - 1, r_random, l_random)
   where
      r_random s    = let g = mkStdGen (rs !! s) 
                          m = fst $ randomR (1, 2^n) g in
                      (sort . nub . take m) $ randomRs (0, 2^n - 1) g
      l_random s pj = if pj == ""
                      then False
                      else let bss = statesbin n
                               k = (read . tail) pj in
                           (bss !! s) !! k





