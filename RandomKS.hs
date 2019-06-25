module RandomKS where
import Core
import Data.List(nub, sort)
import System.Random(mkStdGen, randomR, randomRs)


--Esta función genera un modelo aleatorio con 2^n estados a partir de una lista de semillas.
randomKS::Int->[Int]->KripkeS
randomKS n rs = KS (2^n - 1, r_random, l_random)
   where
      r_random s    = let g = mkStdGen (rs !! s) 
                          m = fst $ randomR (1, n^2) g in
                      (sort . nub . take m) $ randomRs (0, 2^n - 1) g
      l_random s pj = if pj == ""
                      then False
                      else let bss = statesbin n
                               k   = (read . tail) pj in
                           (bss !! s) !! k



statesbin::Int->[[Bool]]
statesbin n = fmap (completeZeros n) $ take (2^n) bins
   where
      bins = [False] : nexts bins 
      nexts (b:bs) = (sucB b) : nexts bs
      sucB []         = [True]
      sucB (False:bs) = True:bs 
      sucB (True:bs)  = False : sucB bs
      completeZeros n bs = let m = length bs in
                           if m < n 
                           then bs++(replicate (n-m) False) 
                           else bs






