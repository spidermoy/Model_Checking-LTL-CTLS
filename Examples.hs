module Examples where

import Control.Monad(forM_)
import Data.Set(singleton)
import Core

{-
  Examples was taken from:
  “LOGIC IN COMPUTER SCIENCE, Modelling and Reasoning about Systems”,
  MICHAEL HUTH & MARK RYAN, Second Edition.
-}


-- Kripke structure from page 179.
kripkeS_example = KS (2, r, l)
    where
      r 0 = [1, 2]
      r 1 = [0, 2]
      r 2 = [2]
      l 0 = \a -> elem a ["p", "q"]
      l 1 = \a -> elem a ["q", "r"]
      l 2 = (== "r")

-- LTL examples from page 182.
ltl_examples = [
          ([0], ConjP (St $ Var "p") (St $ Var "q")),
          ([0], St $ Neg "r"),
          ([0], St top),
          ([0], X $ St $ Var "r"),
          ([0], X $ ConjP (St $ Var "q") (St $ Var "r")),
          ([0], opG $ negP $ ConjP (St $ Var "p") (St $ Var "r")),
          ([2], opG $ St $ Var "r"),
          ([0, 1, 2], impP (opF $ ConjP (St $ Neg "q") (St $ Var "r")) (opF $ opG $ St $ Var "r")),
          ([0], opG $ opF $ St $ Var "p"),
          ([0], impP (opG $ opF $ St $ Var "p") (opG $ opF $ St $ Var "r")),
          ([0], impP (opG $ opF $ St $ Var "r") (opG $ opF $ St $ Var "p"))
               ]

-- LTL examples from page 213.
ctl_examples = [
          (0, ConjS (Var "p") (Var "q")),
          (0, Neg "r"),
          (0, top),
          (0, E $ X $ St $ ConjS (Var "q") (Var "r")),
          (0, negS $ A $ X $ St $ ConjS (Var "q") (Var "r")),
          (0, negS $ E $ opF $ St $ ConjS (Var "p") (Var "r")),
          (2, E $ opG $ St $ Var "r"),
          (0, A $ opF $ St $ Var "r"),
          (0, E $ U (St $ ConjS (Var "p") (Var "q")) (St $ Var "r")),
          (0, A $ U (St $ Var "p") (St $ Var "r")),
          (0, A $ opG $ St $ impS (DisyS (DisyS (Var "p") (Var "q")) (Var "r")) 
                                  (E $ opF $ St $ E $ opG $ St $ Var "r"))
               ]


examples::IO ()
examples = do
        putStrLn "\n\tLTL EXAMPLES:"
        forM_ ltl_examples (\(states, ф) -> do
                              forM_ states (\s -> do
                                              let σ = Assrt (s, singleton ф)
                                              putStr $ show σ ++ ": "
                                              print $ eval_mcALTL kripkeS_example σ))
        putStrLn "\n\tCTL EXAMPLES:"
        forM_ ctl_examples (\(s, φ) -> do
                              putStr $ show (s, φ) ++ ": "
                              print $ eval_mcCTLS kripkeS_example (s, φ)) --(kripkeS_example, s) φ)

