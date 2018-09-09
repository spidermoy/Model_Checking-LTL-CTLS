module Exp_LTL where
import Core
import RandomForms
import ParserNuXmv
import RandomKS
import Data.List(sort,nub)
import System.Random(mkStdGen,randomIO,randoms,randomR,randomRIO,randomRs)
import Control.Monad(when)
import Data.Time(getCurrentTime,diffUTCTime)
import System.Process(readProcess)


experimento_random_LTL::Int->Int->Bool->IO ()
experimento_random_LTL n lforms nuXmv =
                let vars = ["p"++show j | j<-[0..n-1]] 
                    call_mcALTL_set = \fs ks ss -> case fs of {[] -> do {putStrLn ""};f:gs -> do {start <- getCurrentTime;putStrLn $ show f ++" : "++(show $ mcALTL_set ks ss f);end <- getCurrentTime;putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start)++"\n";call_mcALTL_set gs ks ss}}
                in 
                      do
                       ranInit <- randomIO;
                       putStrLn $ " Semilla init: " ++ show ranInit;
                       ranNumInit <- randomIO;
                       putStrLn $ " Semilla NumInit: " ++ show ranNumInit;
                       ranKS <- randomIO;
                       let suc_ks = randoms (mkStdGen ranKS) :: [Int]; 
                       putStrLn $ " Semilla KS: " ++ show ranKS;
                       ranF <- randomIO;
                       putStrLn $ " Semilla F: " ++ show ranF;
                       let k = fst $ randomR (1,2^n) (mkStdGen ranNumInit);
                       let init = sort $ take k $ nub $ randomRs (0,(2^n)-1::Int) (mkStdGen ranInit);
                       let states = [0..(2^n - 1)]; 
                       let ks@(KS (nstates,r,l)) = randomKS n suc_ks;
                       let forms = sort $ randomFormsLTL lforms n ranF;  
                       putStrLn $ "\nMODELO ALEATORIO DE TAMAÑO 2^"++show n;  
                       putStrLn $ "Profundidad de las fórmulas: "++show lforms;
                       putStrLn $ "Verificando las fórmulas: " ++ show forms ++ "\nEstados iniciales: "++(show k)++"\n";
                       when nuXmv (do 
                                    putStrLn "[Creando archivo para NuSMV...]";
                                    write_nuxmvLTL ks states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF];
                                    putStrLn "[Archivo creado]")
                       when nuXmv $ putStr "\n\tmcALTL:\n"; 
                       call_mcALTL_set forms ks init; 
                       when nuXmv (do 
                                    putStrLn "\tNuSMV:\n";
                                    start <- getCurrentTime;
                                    salida_nuXmv <- readProcess "NuSMV" ["-dcx","ejemplo_random.smv"] [];
                                    end <- getCurrentTime;
                                    let salida_nuXmv_forms = let tres_ ss = case ss of {[s1,s2,s3] -> ss;_:sss -> tres_ sss} in (concat . (map $ \s -> s++"\n") . tres_ . lines) salida_nuXmv;
                                    putStrLn salida_nuXmv_forms;
                                    putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start))
 

experimento_seeds_LTL::[Int]->Int->Int->Bool->IO ()
experimento_seeds_LTL [ranInit,ranNumInit,ranKS,ranF] n lforms nuXmv =
                let vars = ["p"++show j | j<-[0..n-1]] 
                    call_mcALTL_set = \fs ks ss -> case fs of {[] -> do {putStrLn ""};f:gs -> do {start <- getCurrentTime;putStrLn $ show f ++" : "++(show $ mcALTL_set ks ss f);end <- getCurrentTime;putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start)++"\n";call_mcALTL_set gs ks ss}}
                in 
                      do
                       putStrLn $ " Semilla init: " ++ show ranInit;
                       putStrLn $ " Semilla NumInit: " ++ show ranNumInit;
                       let suc_ks = randoms (mkStdGen ranKS) :: [Int]; 
                       putStrLn $ " Semilla KS: " ++ show ranKS;
                       putStrLn $ " Semilla F: " ++ show ranF;
                       let k = fst $ randomR (1,2^n) (mkStdGen ranNumInit);
                       let init = sort $ take k $ nub $ randomRs (0,(2^n)-1::Int) (mkStdGen ranInit);
                       let states = [0..(2^n - 1)]; 
                       let ks@(KS (nstates,r,l)) = randomKS n suc_ks;
                       let forms = sort $ randomFormsLTL lforms n ranF;  
                       putStrLn $ "\nMODELO ALEATORIO DE TAMAÑO 2^"++show n;  
                       putStrLn $ "Profundidad de las fórmulas: "++show lforms;
                       putStrLn $ "Verificando las fórmulas: " ++ show forms ++ "\nEstados iniciales: "++(show k)++"\n"; 
                       when nuXmv (do 
                                    putStrLn "[Creando archivo para NuSMV...]";
                                    write_nuxmvLTL ks states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF];
                                    putStrLn "[Archivo creado]")
                       when nuXmv $ putStr "\n\tmcALTL:\n";
                       call_mcALTL_set forms ks init;
                       when nuXmv (do 
                                    putStrLn "\tNuSMV:\n";
                                    start <- getCurrentTime;
                                    salida_nuXmv <- readProcess "NuSMV" ["-dcx","ejemplo_random.smv"] [];
                                    end <- getCurrentTime;
                                    let salida_nuXmv_forms = let tres_ ss = case ss of {[s1,s2,s3] -> ss;_:sss -> tres_ sss} in (concat . (map $ \s -> s++"\n") . tres_ . lines) salida_nuXmv;
                                    putStrLn salida_nuXmv_forms;
                                    putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start))



experimento_LTL::IO Bool
experimento_LTL =
                let  
                    call_mcALTL_set fs ks ss = map (\f -> ((show f)++" : ",mcALTL_set ks ss f)) fs   -- \fs ks ss -> case fs of {[] -> do {putStrLn ""};f:gs -> do {start <- getCurrentTime;putStrLn $ show f ++" : "++(show $ mcALTL_set ks ss f);end <- getCurrentTime;putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start)++"\n";call_mcALTL_set gs ks ss}}
                in 
                      do
                       n <- randomRIO (3,14);
                       let vars = ["p"++show j | j<-[0..n-1]]
                       lforms <- randomRIO (2,3);
                       ranInit <- randomIO;
                       putStrLn $ " Semilla init: " ++ show ranInit;
                       appendFile "tabla_LTL" $ " Semilla init: " ++ show ranInit++"\n";
                       ranNumInit <- randomIO;
                       putStrLn $ " Semilla NumInit: " ++ show ranNumInit;
                       appendFile "tabla_LTL" $ " Semilla NumInit: " ++ show ranNumInit++"\n";
                       ranKS <- randomIO;
                       let suc_ks = randoms (mkStdGen ranKS) :: [Int]; 
                       putStrLn $ " Semilla KS: " ++ show ranKS;
                       appendFile "tabla_LTL" $ " Semilla KS: " ++ show ranKS++"\n";
                       ranF <- randomIO;
                       putStrLn $ " Semilla F: " ++ show ranF;
                       appendFile "tabla_LTL" $ " Semilla F: " ++ show ranF++"\n";
                       let k = fst $ randomR (1,2^n) (mkStdGen ranNumInit);
                       let init = sort $ take k $ nub $ randomRs (0,(2^n)-1::Int) (mkStdGen ranInit);
                       let states = [0..(2^n - 1)]; 
                       let ks@(KS (nstates,r,l)) = randomKS n suc_ks;
                       let forms = sort $ randomFormsLTL lforms n ranF;  
                       putStrLn $ "\nMODELO ALEATORIO DE TAMAÑO 2^"++show n;
                       appendFile "tabla_LTL" $ "\nMODELO ALEATORIO DE TAMAÑO 2^"++show n++"\n"; 
                       putStrLn $ "Profundidad de las fórmulas: "++show lforms;
                       appendFile "tabla_LTL" $ "Profundidad de las fórmulas: "++show lforms++"\n";
                       putStrLn $ "Verificando las fórmulas: " ++ show forms ++ "\nEstados iniciales: "++(show k)++"\n"; 
                       appendFile "tabla_LTL" $ "Verificando las fórmulas: " ++ show forms ++ "\nEstados iniciales: "++(show k)++"\n"++"\n"; 
                       let res_mcALTL@[(s1,b1),(s2,b2),(s3,b3)] = call_mcALTL_set forms ks init;
                       putStr "\n\tmcALTL:\n";
                       appendFile "tabla_LTL" $ "\n\tmcALTL:\n";
                       start <- getCurrentTime;
                       mapM_ putStrLn (map (\(s,b) -> s ++ show b) res_mcALTL);
                       end <- getCurrentTime;
                       appendFile "tabla_LTL" $ (concat $ map (\(s,b) -> s ++ show b++"\n") $ res_mcALTL)++"\n"; 
                       putStrLn $ "\n\tTiempo de verificación: " ++ (show $ diffUTCTime end start);
                       appendFile "tabla_LTL" $ "\n\tTiempo de verificación: " ++ (show $ diffUTCTime end start)++"\n";
                       putStrLn "\n[Creando archivo para NuSMV...]";
                       appendFile "tabla_LTL" $ "\n[Creando archivo para NuSMV...]"++"\n";
                       write_nuxmvLTL ks states init vars forms lforms [ranInit,ranNumInit,ranKS,ranF];
                       putStrLn "[Archivo creado]";
                       appendFile "tabla_LTL" $ "[Archivo creado]"++"\n";
                       start <- getCurrentTime;
                       salida_nuXmv <- readProcess "NuSMV" ["-dcx","ejemplo_random.smv"] [];
                       end <- getCurrentTime;
                       let salida_nuXmv_forms = let tres_ ss = case ss of {[_,_,_] -> ss;_:sss -> tres_ sss} in (tres_ . lines) salida_nuXmv;
                       putStrLn $ "\n\tNuSMV:\n" ++ ((concat . (map $ \s -> s++"\n")) salida_nuXmv_forms);
                       appendFile "tabla_LTL" $ "\n\tNuSMV:\n" ++ ((concat . (map $ \s -> s++"\n")) salida_nuXmv_forms)++"\n";
                       putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start);
                       appendFile "tabla_LTL" $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start)++"\n";
                       let res_nuXmv = let cinco_ ss = case ss of {[_,_,_,_,_]->ss;_:sss -> cinco_ sss} in (map (\s -> case s of {"false" -> False;_ -> True})) $ (map cinco_) salida_nuXmv_forms;
                       let res_exp = (and $ zipWith (==) [b1,b2,b3] res_nuXmv);
                       if res_exp then do 
                                        putStrLn "\t=================================EXPERIMENTO CORRECTO=================================";
                                        appendFile "tabla_LTL" $ "\t=================================EXPERIMENTO CORRECTO================================="++"\n";
                                        return res_exp
                                  else do             
                                        putStrLn "\t=================================EXPERIMENTO INCORRECTO=================================";
                                        appendFile "tabla_LTL" $ "\t=================================EXPERIMENTO INCORRECTO================================="++"\n";
                                        return res_exp
                       

tabla_LTL::Int->IO ()
tabla_LTL n = case n of
           0 -> putStrLn "\n[Experimentos guardados en el archivo “tabla_LTL”]\n\tTODOS LOS EXPERIMENTOS FUERON CORRECTOS\n"
           k -> do
                 putStrLn $ "EXPERIMENTO #"++show k; 
                 appendFile "tabla_LTL" $ "EXPERIMENTO #"++show k++"\n"; 
                 b <- experimento_LTL;
                 when (not b) (error "FALLÓ UN EXPERIMENTO");
                 tabla_LTL (n-1)
                 
                  
           
               
                       
                       
                       
                       
                       
                       
                       
 

