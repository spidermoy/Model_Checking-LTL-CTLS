module RandomForms where

import Core(opF, opG, negP, PathF(..), StateF(..), impP)
import System.Random(mkStdGen,randomRs)


--Dados n,m,s, crea fórmulas LTL aleatorias de longitud n con m variables utilizando la semilla s.
randomFormsLTL::Int->Int->Int->[PathF]
randomFormsLTL n m s = let vars = ["p" ++ show j | j <- [0..m-1]]
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
randomFormsCTL n m s = let vars = ["p" ++ show j | j <- [0..m-1]]
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


{-
  F(p0∧X(p1∧X(p2∧…Xpm−1)))

  La fórmula dice que eventualmente habrá una secuencia de 𝑚 estados consecutivos donde primero 𝑝0 es verdadero, seguido de 𝑝1, etc., hasta 𝑝𝑚−1.

  Si 𝑚≤𝑛 la fórmula puede satisfacerse en la estructura cíclica Mn.
​  Si 𝑚>𝑛 la fórmula no puede satisfacerse en la estructura cíclica Mn.
-}
fmTimesX::Int->PathF
fmTimesX m = opF $ replicateX 0
  where
    replicateX k
      | k == m-1  = St (Var $ 'p' : show k)
      | otherwise = St (Var $ 'p' : show k) `ConjP` X (replicateX $ k+1)


{-
  Propiedad de seguridad (ausencia de ciertos estados):

  G¬(p0∧p1∧…∧pm−1)

  Nunca habrá un estado donde todas las proposiciones 𝑝0,𝑝1,…,𝑝𝑚−1 sean verdaderas simultáneamente.
-}
securityG::Int->PathF
securityG m = opG $ negP $ pathConj 0
  where
    pathConj k
      | k == m-1  = St (Var $ 'p' : show k)
      | otherwise = St (Var $ 'p' : show k) `ConjP` pathConj (k+1)


{-
  Propiedad de vivacidad (alcanzabilidad de estados específicos):

  F(pn−1∧Xp0)

  Eventualmente se alcanzará el último estado etiquetado con 𝑝𝑛−1 seguido del primer estado etiquetado con 𝑝0.
-}
vivacidadF::Int->PathF
vivacidadF n = opF $ St (Var $ 'p' : show (n-1)) `ConjP` X (St (Var $ 'p' : show 0))


{-
  Propiedad de Progreso:

  φprog,n = G(p0→Fp1)∧G(p1→Fp2)∧…∧G(pn−2→Fpn−1)

  Interpretación: Si 𝑝𝑖 es verdadero, eventualmente 𝑝𝑖+1 también será verdadero, para todos los 𝑖 en el rango de 0 a 𝑛−2

  Uso: Verificar que hay un progreso secuencial en el sistema, es decir, que no se queda atrapado en un estado sin avanzar.
-}
progresoG::Int->PathF
progresoG n = replicaGImp 0
  where
    replicaGImp k
      | k == n-2  = opG $ St (Var $ 'p' : show (n-2)) `impP` opF (St $ Var $ 'p' : show (n-1))
      | otherwise = opG (St (Var $ 'p' : show k)      `impP` opF (St $ Var $ 'p' : show (k+1))) `ConjP` replicaGImp (k+1)


{-
  Propiedad de Ausencia de Secuencias Peligrosas:

  φsafe,m = G¬(q0∧X(q1∧X(…Xqm−1)))

  Interpretación: Nunca ocurre una secuencia de 𝑚 estados consecutivos donde primero 𝑞0 es verdadero, seguido de 𝑞1, y así sucesivamente hasta 𝑞𝑚−1.

  Uso: Prevenir secuencias peligrosas o indeseadas de eventos en el sistema.
-}
safeG::Int->PathF
safeG m = opG $ negP $ replicateX 0
  where
    replicateX k
      | k == m-1  = St (Var $ 'p' : show k)
      | otherwise = St (Var $ 'p' : show k) `ConjP` X (replicateX $ k+1)


{-
  Propiedad de Permanencia:

  φperm,k = G(Fp0→G(p0∧X(p1∧X(…Xpk−1))))

  Interpretación: Si 𝑝0 es verdadero alguna vez, entonces siempre habrá una secuencia repetida de 𝑝0,𝑝1,…,𝑝𝑘−1.

  Uso: Asegurar que una vez alcanzado un estado particular, se mantiene una secuencia estable de eventos.
-}
permGF::Int->PathF
permGF m = opG $ opF (St (Var $ 'p' : show 0)) `impP` opG (replicateX 0)
  where
    replicateX k
      | k == m-1  = St (Var $ 'p' : show k)
      | otherwise = St (Var $ 'p' : show k) `ConjP` X (replicateX $ k+1)


{-
  Propiedad de Repetición Periódica:

  φrepeat,n = G(p0​→F(p1∧F(p2∧…Fpn−1)))

  Interpretación: Si 𝑝0 es verdadero, entonces eventualmente ocurrirá 𝑝1, seguido de 𝑝2, y así sucesivamente hasta 𝑝𝑛−1, repetidamente.

  Uso: Verificar que una secuencia de eventos ocurre de forma cíclica o periódica.
-}
repeatG::Int->PathF
repeatG n = opG $ St (Var $ 'p' : show 0) `impP` replicateF 1
  where
    replicateF k
      | k == n-1  = opF $ St (Var $ 'p' : show k)
      | otherwise = opF $ St (Var $ 'p' : show k) `ConjP` replicateF (k+1)


{-
  Propiedad de Alternancia:

  φalt,m = G(p0→(Fp1∨Fp2∨…∨Fpm−1))

  Interpretación: Si 𝑝0 es verdadero, eventualmente uno de 𝑝1,𝑝2,…,𝑝𝑚−1 será verdadero.

  Uso: Especificar que después de un evento inicial, al menos una de varias opciones posibles debe ocurrir.
-}
altG::Int->PathF
altG m = opG $ St (Var $ 'p' : show 0) `impP` replicateF 1
  where
    replicateF k
      | k == m-1  = opF $ St (Var $ 'p' : show k)
      | otherwise = opF (St $ Var $ 'p' : show k) `DisyP` replicateF (k+1)


{-
  Patrón de ciclo completo parametrizado:

  φcycle,n = G((p0∧Xp1∧…∧X^(n−1)pn−1)→X^np0

  Interpretación: Después de una secuencia completa de 𝑝0,𝑝1,…,𝑝𝑛−1, el ciclo se repite desde 𝑝0.

  Uso: Modelar ciclos completos de eventos que se repiten indefinidamente.
 )
-}
cicloCompletoG::Int->PathF
cicloCompletoG n = opG $ conjX 0 `impP` replicateX (St $ Var $ 'p' : show 0) n
  where
    replicateX f k
      | k == 0    = f
      | otherwise = replicateX (X f) (k-1)
    conjX k
      | k == n-1  = replicateX (St $ Var $ 'p' : show k) k
      | otherwise = replicateX (St $ Var $ 'p' : show k) k `ConjP` conjX (k+1)
