module Examples where

import Control.Monad(forM_)
import Data.Set(singleton)
import Core(
    Assertion(Assrt),
    KripkeS(..),
    State,
    PathF(St, ConjP, X, U),
    StateF(..),
    negS,
    negP,
    top,
    opG,
    opF,
    impS,
    impP,
    evalMcALTL,
    evalMcCTLS
  )


{- Kripke structure from page 179. -}
kripkeSExample::KripkeS
kripkeSExample = KS (2, r, l)
  where
    r 0 = [1, 2]
    r 1 = [0, 2]
    r 2 = [2]
    r _ = []
    l 0 = (`elem` ["p", "q"])
    l 1 = (`elem` ["q", "r"])
    l 2 = (== "r")
    l _ = const False


{- LTL examples from page 182. -}
ltlExamples::[([Int], PathF)]
ltlExamples = [
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


{- CTL examples from page 213. -}
ctlExamples::[(State, StateF)]
ctlExamples = [
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
  putStrLn "Kripke Structure:"
  putStrLn $ "\tStates: " ++ show [0, 1, 2]
  putStrLn "\t R(0) = [1, 2]"
  putStrLn "\t R(1) = [0, 2]"
  putStrLn "\t R(2) = [2]"
  putStrLn "\t L(0) = [p, q]"
  putStrLn "\t L(1) = [q, r]"
  putStrLn "\t L(2) = [r]"
  putStrLn "\n\tLTL EXAMPLES:"
  forM_ ltlExamples $ \(states, ф) -> forM_ states (\s -> do
    let σ = Assrt (s, singleton ф)
    putStr $ show σ ++ ": "
    print $ evalMcALTL kripkeSExample σ)
  putStrLn "\n\tCTL EXAMPLES:"
  forM_ ctlExamples (\(s, φ) -> do
    putStr $ show (s, φ) ++ ": "
    print $ evalMcCTLS kripkeSExample (s, φ))
  putStrLn "\nExamples from:"
  putStrLn "Michael Huth & Mark Ryan, “LOGIC IN COMPUTER SCIENCE, Modelling and Reasoning about Systems”, Second Edition."
