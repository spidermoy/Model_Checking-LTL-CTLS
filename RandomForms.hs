module RandomForms where

import Core(opF, opG, PathF(..), StateF(..))
import System.Random(mkStdGen,randomRs)


--Dados n,m,s, crea fórmulas LTL aleatorias de longitud n con m variables utilizando la semilla s.
randomFormsLTL::Int->Int->Int->[PathF]
randomFormsLTL n m s = let vars = ["p"++show j | j <- [0..m-1]]
                           tipF = randomRs (0,6)   (mkStdGen s) :: [Int]
                           indV = randomRs (0,m-1) (mkStdGen s) :: [Int] in
                       [
                         randF tipF indV vars 0 0 n,
                         randF tipF indV vars 1 5 n,
                         randF tipF indV vars 2 10 n
                       ]
  where
    randF _ indV vars k _ 0 = let k' = mod k m in
                              if   mod (indV !! k') 6 == 0
                              then St (Neg $ vars !! k')
                              else St (Var $ vars !! k')
    randF tipF indV vars k m' n' = case tipF !! m' of
      0 -> ConjP (randF tipF indV vars (k+7) (m'+1) (n'-1)) (randF tipF indV vars (k+3) (m'+2) (n'-1))
      1 -> X     (randF tipF indV vars (k+1) (m'+2) (n'-1))
      2 -> opG   (randF tipF indV vars (k+2) (m'+3) (n'-1))
      3 -> DisyP (randF tipF indV vars (k+3) (m'+4) (n'-1)) (randF tipF indV vars (k+4) (m'+5) (n'-1))
      4 -> opF   (randF tipF indV vars (k+1) (m'+2) (n'-1))
      5 -> U     (randF tipF indV vars (k+5) (m'+6) (n'-1)) (randF tipF indV vars (k+2) (m'+3) (n'-1))
      6 -> V     (randF tipF indV vars (k+6) (m'+7) (n'-1)) (randF tipF indV vars (k+1) (m'+2) (n'-1))
      _ -> St $ Var ""


--Dados n,m,s, crea fórmulas CTL aleatorias de longitud n con m variables utilizando la semilla s.
randomFormsCTL::Int->Int->Int->[StateF]
randomFormsCTL n m s = let vars = ["p"++show j | j<-[0..m-1]]
                           tipF = randomRs (0,9)   (mkStdGen s) :: [Int]
                           indV = randomRs (0,m-1) (mkStdGen s) :: [Int] in
                       [
                         randF tipF indV vars 0 0 n,
                         randF tipF indV vars 1 5 n,
                         randF tipF indV vars 2 10 n
                       ]
  where
    randF _    indV vars k _ 0 = let k' = mod k m in
                                 if   mod (indV !! k') 6 == 0
                                 then Neg $ vars !! k'
                                 else Var $ vars !! k'
    randF tipF indV vars k m' n' = case tipF !! m of
      0 -> ConjS (        randF tipF indV vars (k+7)  (m'+1)  (n'-1)) (randF tipF indV      vars (k+3) (m'+2) (n'-1))
      1 -> DisyS (        randF tipF indV vars (k+2)  (m'+4)  (n'-1)) (randF tipF indV      vars (k+5) (m'+1) (n'-1))
      2 -> A $ X $ St $   randF tipF indV vars (k+8)  (m'+2)  (n'-1)
      3 -> E $ X $ St $   randF tipF indV vars (k+6)  (m'+5)  (n'-1)
      4 -> A $ U (St $    randF tipF indV vars (k+4)  (m'+10) (n'-1)) (St $ randF tipF indV vars (k+9)  (m'+9) (n'-1))
      5 -> E $ U (St $    randF tipF indV vars (k+14) (m'+12) (n'-1)) (St $ randF tipF indV vars (k+76) (m'+3) (n'-1))
      6 -> A $ opG $ St $ randF tipF indV vars (k+5)  (m'+5)  (n'-1)
      7 -> E $ opG $ St $ randF tipF indV vars (k+3)  (m'+3)  (n'-1)
      8 -> A $ opF $ St $ randF tipF indV vars (k+31) (m'+31) (n'-1)
      9 -> E $ opF $ St $ randF tipF indV vars (k+7)  (m'+7)  (n'-1)
      _ -> Var ""
