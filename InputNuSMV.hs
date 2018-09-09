module InputNuSMV where

import Lexer
import Parser
import Syntax
import Core
import Data.Time(getCurrentTime,diffUTCTime)
import System.Process(readProcess)


parse_file::FilePath->IO (KripkeS,[State],[Either PathF StateF])
parse_file file_path = do 
           module_file <- (readFile file_path) >>= return . head . (fmap moduleBody) . nusmv . alexScanTokens;
           let (VarDeclaration vars) = module_file !! 0 
           let (DefineDeclaration define) = module_file !! 1;
           let parse_define = \expr -> case expr of {IdExpr (ComplexId (Just p) _) -> [p];UnExpr OpNot _ -> [];BinExpr OpAnd e1 e2 -> parse_define e1 ++ parse_define e2};                                          
           let ks_l = [(read (tail s) :: Int,parse_define l_s) | (s,l_s) <- define];
           let (InitConstraint inits) = module_file !! 2;
           let parse_inits = \expr -> case expr of {IdExpr (ComplexId (Just s) _) -> [read (tail s)::Int];BinExpr OpOr e1 e2 -> parse_inits e1 ++ parse_inits e2}
           let ks_inits = parse_inits inits;
           let (TransConstraint trans) = module_file !! 3;
           let parse_ors = \expr -> case expr of {BinExpr OpOr e1 e2 -> parse_ors e1 ++ parse_ors e2; e -> [e]};
           let parse_ands = \expr -> case expr of {BinExpr OpAnd e1 e2 -> parse_ors e1 ++ parse_ors e2; e -> [e]};
           let specs = drop 4 module_file;
           let parse_LTL = \expr -> case expr of 
                                     IdExpr (ComplexId (Just p) _) -> St $ Var p
                                     UnExpr OpNot (IdExpr (ComplexId (Just p) _)) -> St $ Neg p
                                     UnExpr OpNot e -> negP $ parse_LTL e   
                                     BinExpr OpAnd e1 e2 -> ConjP (parse_LTL e1) (parse_LTL e2)
                                     BinExpr OpOr e1 e2 -> DisyP (parse_LTL e1) (parse_LTL e2)
                                     BinExpr OpImpl e1 e2 -> DisyP (negP $ parse_LTL e1) (parse_LTL e2)
                                     BinExpr OpU e1 e2 -> U (parse_LTL e1) (parse_LTL e2)
                                     BinExpr OpV e1 e2 -> R (parse_LTL e1) (parse_LTL e2)
                                     UnExpr LTLF e -> opF $ parse_LTL e
                                     UnExpr LTLG e -> opG $ parse_LTL e
                                     UnExpr LTLX e -> X $ parse_LTL e                                    
           let parse_CTL = \expr -> case expr of
                                     IdExpr (ComplexId (Just p) _) -> Var p
                                     UnExpr OpNot (IdExpr (ComplexId (Just p) _)) -> Neg p
                                     UnExpr OpNot e -> negS $ parse_CTL e   
                                     BinExpr OpAnd e1 e2 -> ConjS (parse_CTL e1) (parse_CTL e2)
                                     BinExpr OpOr e1 e2 -> DisyS (parse_CTL e1) (parse_CTL e2)
                                     BinExpr OpImpl e1 e2 -> DisyS (negS $ parse_CTL e1) (parse_CTL e2)
                                     UnExpr CTLAG e -> A $ opG $ St $ parse_CTL e
                                     UnExpr CTLEG e -> E $ opG $ St $ parse_CTL e
                                     UnExpr CTLAF e -> A $ opF $ St $ parse_CTL e
                                     UnExpr CTLEF e -> E $ opF $ St $ parse_CTL e
                                     UnExpr CTLAX e -> A $ X $ St $ parse_CTL e
                                     UnExpr CTLEX e -> E $ X $ St $ parse_CTL e
                                     BinExpr CTLAU e1 e2 -> A $ U (St $ parse_CTL e1) (St $ parse_CTL e2)
                                     BinExpr CTLEU e1 e2 -> E $ U (St $ parse_CTL e1) (St $ parse_CTL e2)
           let specs_module = fmap (\expr -> case expr of {LTLSpec e' -> Left $ parse_LTL e';CTLSpec e' -> Right $ parse_CTL e'}) specs; 
           let ks_r = fmap (\[IdExpr (ComplexId (Just s) _),UnExpr OpNext s_nexts] -> (read (tail s)::Int,parse_inits s_nexts)) $ fmap parse_ands $ parse_ors trans;
           let kripS = KS (2^(length vars)::Int,crea_r ks_r,crea_l ks_l) where
                                             crea_r [] = (\_ -> []) 
                                             crea_r ((r,r_nexts):rs) = \s -> if s==r then r_nexts else crea_r rs s
                                             crea_l [] = \_ -> \_ -> False
                                             crea_l ((s,l_s):ls) = \s' p -> if s'==s then elem p l_s else crea_l ls s' p;
           return (kripS,ks_inits,specs_module)
          
          
          
experimento_input::FilePath->IO ()
experimento_input file_path = do
                  start <- getCurrentTime;
                  putStrLn "[Leyendo archivo]";
                  (ks,ks_inits,specs) <- parse_file file_path;
                  let f = \specs -> case specs of 
                                     [] -> return ()
                                     sp:sps -> case sp of
                                                Left ltlform -> do 
                                                                 
                                                                 putStrLn "\n\tmcALTL:";
                                                                 putStrLn $ show ltlform ++ " : "++(show $ mcALTL_set ks ks_inits ltlform);
                                                                 f sps
                                                Right ctlform -> do 
                                                                 putStrLn "\n\tmcCTLS:";
                                                                 putStrLn $ show ctlform ++ " : "++(show $ mcCTLS_set (ks,ks_inits) ctlform);
                                                                 f sps                 
                  f specs;            
                  end <- getCurrentTime;
                  putStrLn $ "\n\tTiempo de verificación: " ++ (show $ diffUTCTime end start)
                  putStrLn "\n[NuSMV]";
                  start <- getCurrentTime;
                  salida_nuXmv <- readProcess "NuSMV" ["-dcx",file_path] [];
                  end <- getCurrentTime;
                  let salida_nuXmv_forms = let specs_ ss = if length ss == length specs then ss else specs_ (tail ss) in (concat . (map $ \s -> s++"\n") . specs_ . lines) salida_nuXmv;
                  putStrLn $ "\n\tnuXmv:\n" ++ salida_nuXmv_forms;
                  putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start)         
                                            
                                     
                                     
                                     
                                     
                  



