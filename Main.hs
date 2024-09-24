module Main where

import System.Environment(getArgs)
import Experiments(
    TypeExperiment(CTL, LTL, LTLc),
    randomExperiment,
    seedsExperiment,
    thesisExperiments,
    ltlExperiment
  )
import Examples(examples)


main::IO ()
main = do
  args <- getArgs
  case args of
    -- Random experiment comparing with nuXmv.
    ["random", "nuXmv", experiment, n_vars, forms_n]                                 -> random_exp experiment n_vars forms_n True
    -- Random experiment.
    ["random", experiment, n_vars, forms_n]                                          -> random_exp experiment n_vars forms_n False
    -- Experiment with initial seeds comparing with nuXmv.
    ["seeds", "nuXmv",ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n] -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n True
    -- Experiment with initial seeds.
    ["seeds", ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n]         -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n False
    -- Experiments in my thesis.
    ["thesis-experiments"]                                                           -> thesisExperiments
    -- Examples in “LOGIC IN COMPUTER SCIENCE, Modelling and Reasoning about Systems”.
    ["examples"]                                                                     -> examples
    ["LTL-experiment", ks_type, n, specification, m]                                 -> ltlExperiment ks_type (read n) specification (read m) False
    ["LTL-experiment", ks_type, n, specification, m, "nuXmv"]                        -> ltlExperiment ks_type (read n) specification (read m) True
    _                                                                                -> putStrLn "opción no válida"
  where
    random_exp experiment n_vars forms_n nuXmv = case experiment of
      "LTL"  -> randomExperiment LTL  (read n_vars) (read forms_n) nuXmv
      "LTLc" -> randomExperiment LTLc (read n_vars) (read forms_n) nuXmv
      "CTL"  -> randomExperiment CTL  (read n_vars) (read forms_n) nuXmv
      _      -> putStrLn "Las opciones válidas son LTL, LTLc Y CTL."
    seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n nuXmv = case experiment of
      "LTL"  -> seedsExperiment LTL  (read ranInit, read ranNumInit, read ranKS, read ranF) (read n_vars) (read forms_n) nuXmv
      "LTLc" -> seedsExperiment LTLc (read ranInit, read ranNumInit, read ranKS, read ranF) (read n_vars) (read forms_n) nuXmv
      "CTL"  -> seedsExperiment CTL  (read ranInit, read ranNumInit, read ranKS, read ranF) (read n_vars) (read forms_n) nuXmv
      _      -> putStrLn "Las opciones válidas son LTL, LTLc Y CTL."
