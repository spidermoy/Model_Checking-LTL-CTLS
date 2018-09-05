module ParserNuXmv where
import Core
import ParserForms
import Binarios

write_nuxmvLTL::KripkeS->[State]->[State]->[String]->[PathF]->Int->[Int]->IO ()
write_nuxmvLTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] = 
                          writeFile "ejemplo_random.smv" (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
                          "MODULE main\n\n" ++
                          "VAR\n"++ let f = \vs -> case vs of {[v] -> v++": boolean;\n\n\n";w:ws -> w++": boolean;\n"++f ws} in f vars ++                      
                          "DEFINE\n"++let f = \s vs -> case vs of {[v] -> if l s v then " "++v++";\n" else "!"++v++";\n";w:ws -> if l s w then " "++w++" & "++ f s ws else "!"++w++" & "++ f s ws} in concat ["s"++show s++":= "++f s vars | s <- states] ++ "\n\n"++
                          "INIT\n"++let f = \sts -> case sts of {[s] -> "s"++show s++";\n\n";s':ss -> "s"++show s'++" | "++f ss} in f init ++
                          "TRANS\n"++let g = \sts -> case sts of {[s] -> "s"++show s;s':ss -> "s"++show s'++"|"++g ss} in let f = \sts -> case sts of {[s] -> "(s"++show s++" & next("++ (g . r) s ++"))\n\n";s':ss -> "(s"++show s'++" & next("++ (g . r) s' ++")) |\n"++ f ss} in f states++
                          pathFormsToFile forms)
                              

write_nuxmvCTL::KripkeS->[State]->[State]->[String]->[StateF]->Int->[Int]->IO ()
write_nuxmvCTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] = 
                          writeFile "ejemplo_random.smv" (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
                          "MODULE main\n\n" ++
                          "VAR\n"++ let f = \vs -> case vs of {[v] -> v++": boolean;\n\n\n";w:ws -> w++": boolean;\n"++f ws} in f vars ++                      
                          "DEFINE\n"++let f = \s vs -> case vs of {[v] -> if l s v then " "++v++";\n" else "!"++v++";\n";w:ws -> if l s w then " "++w++" & "++ f s ws else "!"++w++" & "++ f s ws} in concat ["s"++show s++":= "++f s vars | s <- states] ++ "\n\n"++
                          "INIT\n"++let f = \sts -> case sts of {[s] -> "s"++show s++";\n\n";s':ss -> "s"++show s'++" | "++f ss} in f init ++
                          "TRANS\n"++let g = \sts -> case sts of {[s] -> "s"++show s;s':ss -> "s"++show s'++"|"++g ss} in let f = \sts -> case sts of {[s] -> "(s"++show s++" & next("++ (g . r) s ++"))\n\n";s':ss -> "(s"++show s'++" & next("++ (g . r) s' ++")) |\n"++ f ss} in f states++
                          stateFormsToFile forms)
                         
                          
{-                     
write_nuxmvLTL::KripkeS->[State]->[State]->[String]->[PathF]->Int->[Int]->IO ()
write_nuxmvLTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] = 
                          writeFile "/home/moy/nuXmv-1.1.1-Linux/bin/ejemplo_random.smv" (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
                          "MODULE main\n\n" ++
                          "VAR\n\tstate: {" ++ let f = \vs -> case vs of {[s] -> "s"++show s;w:ws -> "s"++show w++","++f ws} in f states ++ "};\n\n" ++
                          let f_init = \ss -> case ss of {[s] -> "s"++show s; t:ts -> "s"++show t ++ "," ++ f_init ts }  in "ASSIGN\n\tinit(state) := {"++ f_init init ++"};\n\tnext(state) := case\n"++ let g = \sts -> case sts of {[s] -> "s"++show s;s:ss -> "s"++show s++","++g ss} in let f = \sts -> case sts of {[] -> "\tesac;\n\n";s:ss -> "\t\tstate = s"++show s++" : {"++g (r s) ++"};\n"++ f ss} in f states ++                                        
                          "DEFINE\n"++let g = \sts -> case sts of {[] -> "FALSE;\n";[s] -> "state = s"++show s++";\n";s:ss -> "state = s"++show s++" | "++g ss} in let f = \vs -> case vs of {[] -> "\n\n";v:vs -> let ss = [s | s<-states, l s v] in "\t"++v++" := "++g ss++f vs} in f vars ++                      
                          pathFormsToFile forms) 
                              

write_nuxmvCTL::KripkeS->[State]->[State]->[String]->[StateF]->Int->[Int]->IO ()
write_nuxmvCTL ks@(KS (nstates,r,l)) states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF] = 
                          writeFile "/home/moy/nuXmv-1.1.1-Linux/bin/ejemplo_random.smv" (("-- Semilla init: " ++ show ranInit)++("\n-- Semilla NumInit: " ++ show ranNumInit) ++ ("\n-- Semilla KS: " ++ show ranKS) ++ ("\n-- Semilla F: " ++ show ranF)++("\n-- Longitud fórmulas: "++show lforms)++"\n\n\n"++
                          "MODULE main\n\n" ++
                          "VAR\n\tstate: {" ++ let f = \vs -> case vs of {[s] -> "s"++show s;w:ws -> "s"++show w++","++f ws} in f states ++ "};\n\n" ++
                          let f_init = \ss -> case ss of {[s] -> "s"++show s; t:ts -> "s"++show t ++ "," ++ f_init ts }  in "ASSIGN\n\tinit(state) := {"++ f_init init ++"};\n\tnext(state) := case\n"++ let g = \sts -> case sts of {[s] -> "s"++show s;s:ss -> "s"++show s++","++g ss} in let f = \sts -> case sts of {[] -> "\tesac;\n\n";s:ss -> "\t\tstate = s"++show s++" : {"++g (r s) ++"};\n"++ f ss} in f states ++                                        
                          "DEFINE\n"++let g = \sts -> case sts of {[] -> "FALSE;\n";[s] -> "state = s"++show s++";\n";s:ss -> "state = s"++show s++" | "++g ss} in let f = \vs -> case vs of {[] -> "\n\n";v:vs -> let ss = [s | s<-states, l s v] in "\t"++v++" := "++g ss++f vs} in f vars ++                      
                          stateFormsToFile forms) -}
