module ParserNuXmv where
import Core
import ParserForms


write_nuxmvLTL::KripkeS->[State]->[State]->[String]->[PathF]->Int->[Int]->IO ()
write_nuxmvLTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] =
    writeFile smv_output
        (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
        "MODULE main\n\n" ++
        "VAR\n"++ let f = \vs -> case vs of {[v] -> v++": boolean;\n\n\n";w:ws -> w++": boolean;\n"++f ws} in f vars ++
        "DEFINE\n"++let f = \s vs -> case vs of {[v] -> if l s v then " "++v++";\n" else "!"++v++";\n";w:ws -> if l s w then " "++w++" & "++ f s ws else "!"++w++" & "++ f s ws} in concat ["s"++show s++":= "++f s vars | s <- states] ++ "\n\n"++
        "INIT\n"++let f = \sts -> case sts of {[s] -> "s"++show s++";\n\n";s':ss -> "s"++show s'++" | "++f ss} in f init ++
        "TRANS\n"++let g = \sts -> case sts of {[s] -> "s"++show s;s':ss -> "s"++show s'++"|"++g ss} in let f = \sts -> case sts of {[s] -> "(s"++show s++" & next("++ (g . r) s ++"))\n\n";s':ss -> "(s"++show s'++" & next("++ (g . r) s' ++")) |\n"++ f ss} in f states++
        pathFormsToFile forms)


write_nuxmvCTL::KripkeS->[State]->[State]->[String]->[StateF]->Int->[Int]->IO ()
write_nuxmvCTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] =
    writeFile smv_output
        (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
        "MODULE main\n\n" ++
        "VAR\n"++ let f = \vs -> case vs of {[v] -> v++": boolean;\n\n\n";w:ws -> w++": boolean;\n"++f ws} in f vars ++
        "DEFINE\n"++let f = \s vs -> case vs of {[v] -> if l s v then " "++v++";\n" else "!"++v++";\n";w:ws -> if l s w then " "++w++" & "++ f s ws else "!"++w++" & "++ f s ws} in concat ["s"++show s++":= "++f s vars | s <- states] ++ "\n\n"++
        "INIT\n"++let f = \sts -> case sts of {[s] -> "s"++show s++";\n\n";s':ss -> "s"++show s'++" | "++f ss} in f init ++
        "TRANS\n"++let g = \sts -> case sts of {[s] -> "s"++show s;s':ss -> "s"++show s'++"|"++g ss} in let f = \sts -> case sts of {[s] -> "(s"++show s++" & next("++ (g . r) s ++"))\n\n";s':ss -> "(s"++show s'++" & next("++ (g . r) s' ++")) |\n"++ f ss} in f states++
        stateFormsToFile forms)


