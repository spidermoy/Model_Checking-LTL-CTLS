module Main where
import System.Environment(getArgs)
import Experiments
import Examples

main::IO ()
main = do
    args <- getArgs
    case args of
      ["random", "nuXmv", experiment, n_vars, forms_n] -> random_exp experiment n_vars forms_n True
      ["random", experiment, n_vars, forms_n]          -> random_exp experiment n_vars forms_n False
      ["seeds", "nuXmv",ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n]
                          -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n True
      ["seeds", ranInit, ranNumInit, ranKS, ranF, experiment, n_vars, forms_n]
                          -> seeds_exp ranInit ranNumInit ranKS ranF experiment n_vars forms_n False
      ["thesis_experiments"] -> thesis_experiments
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


