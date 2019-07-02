module Main where

import System.Environment(getArgs)
import Experiments
import Examples


main::IO ()
main = do
    args <- getArgs
    case args of
      -- Random experiment comparing with nuXmv.
      ["random", "nuXmv", experiment, n_vars, forms_n] -> random_exp experiment n_vars forms_n True
      -- Random experiment.
      ["random", experiment, n_vars, forms_n]          -> random_exp experiment n_vars forms_n False
      -- Experiment with initial seeds comparing with nuXmv.
      ["seeds", "nuXmv",ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n]
                          -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n True
      -- Experiment with initial seeds.
      ["seeds", ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n]
                          -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n False
      -- Experiments in my thesis.
      ["thesis_experiments"] -> thesis_experiments
      -- Examples in “LOGIC IN COMPUTER SCIENCE, Modelling and Reasoning about Systems”.
      ["examples"] -> examples
      _ -> putStrLn "Invalid arguments"
    where
      random_exp experiment n_vars forms_n nuXmv = case experiment of
                                 "LTL"  -> random_experiment LTL  (read n_vars) (read forms_n) nuXmv
                                 "LTLc" -> random_experiment LTLc (read n_vars) (read forms_n) nuXmv
                                 "CTL"  -> random_experiment CTL  (read n_vars) (read forms_n) nuXmv
      seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n nuXmv =
          case experiment of
            "LTL"  -> seeds_experiment LTL  (map read [ranInit, ranNumInit, ranKS, ranF])
                                                                  (read n_vars) (read forms_n) nuXmv
            "LTLc" -> seeds_experiment LTLc (map read [ranInit, ranNumInit, ranKS, ranF])
                                                                  (read n_vars) (read forms_n) nuXmv
            "CTL"  -> seeds_experiment CTL  (map read [ranInit, ranNumInit, ranKS, ranF])
                                                                  (read n_vars) (read forms_n) nuXmv


