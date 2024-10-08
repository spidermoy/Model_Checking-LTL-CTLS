module RandomKS where
import Core(KripkeS(..))
import Data.List(nub, sort)
import System.Random(mkStdGen, randomR, randomRs)


--Esta función genera un modelo aleatorio con 2^n estados a partir de una lista de semillas.
randomKS::Int->[Int]->KripkeS
randomKS n rs = KS (r_random, l_random)
  where
    r_random s    = let g = mkStdGen (rs !! s)
                        m = fst $ randomR (1, n^2) g in
                    (sort . nub . take m) $ randomRs (0, 2^n - 1) g
    l_random s pj = pj /= "" && (statesbin n !! s) !! (read . tail) pj


statesbin::Int->[[Bool]]
statesbin n = completeZeros n <$> take (2^n) bins
  where
    bins = [False] : nexts bins
    nexts bss = case bss of
      (b:bs) -> sucB b : nexts bs
      _      -> []
    sucB []         = [True]
    sucB (False:bs) = True  : bs
    sucB (True:bs)  = False : sucB bs
    completeZeros n' bs = let m = length bs in
                          if   m < n'
                          then bs ++ replicate (n'-m) False
                          else bs


cycleKS::Int->KripkeS
cycleKS n = KS (r, l)
  where
    r i
      | i < n     = [(i + 1) `mod` n]
      | otherwise = []
    l s p = s >= 0 && s < n && p == 'p' : show s
