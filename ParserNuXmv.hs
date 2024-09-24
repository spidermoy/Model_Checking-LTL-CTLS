module ParserNuXmv where

import Core(smvOutput, KripkeS(..), PathF, State, StateF)
import ParserForms(pathFormsToFile, stateFormsToFile)


writeNuXmv::KripkeS->[State]->[State]->[String]->Either [PathF] [StateF]->Int->(Int,Int,Int,Int)->IO ()
writeNuXmv (KS (r, l)) states inits vars forms lforms (ranInit, ranNumInit, ranKS, ranF) =
  writeFile smvOutput $
    ("-- init seed: "               ++ show ranInit)    ++
    ("\n-- NumInit seed: "          ++ show ranNumInit) ++
    ("\n-- KS seed: "               ++ show ranKS)      ++
    ("\n-- F seed: "                ++ show ranF)       ++
    ("\n-- Depth of the formulas: " ++ show lforms)     ++ "\n\n\n" ++
    "MODULE main\n\n" ++
    "VAR\n" ++
        let f vs = case vs of
              [v]  -> v ++ ": boolean;\n\n\n"
              w:ws -> w ++ ": boolean;\n" ++ f ws
              _    -> "" in
        f vars ++
    "DEFINE\n" ++ let g s vs = case vs of
                        [v]  -> if   l s v
                                then " " ++ v ++ ";\n"
                                else "!" ++ v ++ ";\n"
                        w:ws -> if   l s w
                                then " " ++ w ++ " & " ++ g s ws
                                else "!" ++ w ++ " & " ++ g s ws
                        _    -> "" in
                  concat ["s" ++ show s ++ ":= " ++ g s vars | s <- states] ++ "\n\n" ++
    "INIT\n" ++ let f' sts = case sts of
                      [s]   -> "s" ++ show s  ++ ";\n\n"
                      s':ss -> "s" ++ show s' ++ " | " ++ f' ss
                      _     -> "" in
                f' inits ++
    "TRANS\n" ++ let g' sts = case sts of
                        [s]   -> "s" ++ show s
                        s':ss -> "s" ++ show s' ++ "|" ++ g' ss
                        _     -> ""
                     f'' sts = case sts of
                        [s]   -> "(s" ++ show s  ++ " & next(" ++ (g' . r) s  ++ "))\n\n"
                        s':ss -> "(s" ++ show s' ++ " & next(" ++ (g' . r) s' ++ ")) |\n" ++ f'' ss
                        _     -> "" in
                 f'' states ++ (case forms of
                                Left  ltl_forms -> pathFormsToFile  ltl_forms
                                Right ctl_forms -> stateFormsToFile ctl_forms)
