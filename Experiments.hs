module Experiments where

import Data.List(sort, nub)
import Data.Set(singleton)
import System.Random(mkStdGen, randomIO, randoms, randomR, randomRIO, randomRs)
import Control.Monad(when)
import Data.Time(getCurrentTime, diffUTCTime)
import System.Process(readProcess)

import Core
import RandomForms
import RandomKS
import ParserNuXmv

data TypeExperiment = LTL | LTLc | CTL


seeds_experiment::TypeExperiment->[Int]->Int->Int->Bool->IO ()
seeds_experiment experiment [ranInit, ranNumInit, ranKS, ranF] n lforms nuXmv =
   let vars                 = ["p" ++ show j | j <- [0 .. n - 1]]
       call_LTLmodelChecker = \fs ks ss -> case fs of
                                        []   -> putStrLn ""
                                        g:gs -> do
                                            start <- getCurrentTime
                                            putStr $ show g ++ " : " ++
                                                     show (mcALTL_set ks ss g)
                                            end   <- getCurrentTime
                                            putStrLn $ "\n\tTiempo de verificación: " ++
                                                       (show $ diffUTCTime end start) ++ "\n"
                                            call_LTLmodelChecker gs ks ss
       call_LTLmodelChecker_CounterExample = \fs ks ss -> case fs of
                                        []   -> putStrLn ""
                                        g:gs -> do
                                            start <- getCurrentTime
                                            putStr $ show g ++ " : "
                                            mcALTLc_set ks ss g
                                            end   <- getCurrentTime
                                            putStrLn $ "\n\tTiempo de verificación: " ++
                                                       (show $ diffUTCTime end start) ++ "\n"
                                            call_LTLmodelChecker_CounterExample gs ks ss
       call_CTLmodelChecker = \fs ks ss -> case fs of
                                        []   -> putStrLn ""
                                        g:gs -> do
                                            start <- getCurrentTime
                                            putStr $ show g ++ " : " ++ 
                                                     show (mcCTLS_set (ks, ss) g)
                                            end   <- getCurrentTime
                                            putStrLn $ "\n\tTiempo de verificación: " ++
                                                       (show $ diffUTCTime end start) ++ "\n"
                                            call_CTLmodelChecker gs ks ss
   in do
       let suc_ks                  = randoms (mkStdGen ranKS) :: [Int]
           k                       = fst $ randomR (1, 2^n) (mkStdGen ranNumInit)
           init                    = sort $ take k $ nub $ randomRs (0, 2^n - 1 :: Int)
                                                                                 (mkStdGen ranInit)
           states                  = [0 .. (2^n - 1)]
           ks@(KS (nstates, r, l)) = randomKS n suc_ks
       putStrLn $ "\nMODELO ALEATORIO DE TAMAÑO 2^" ++ show n
       putStrLn $ "Profundidad de las fórmulas: "   ++ show lforms
       putStrLn $ "Estados iniciales: "             ++ show k
       case experiment of
         LTL  -> let forms = sort $ randomFormsLTL lforms n ranF in
                do
                 putStrLn $ "Forms: " ++ show forms
                 putStrLn "\n\tmcALTL:\n"
                 call_LTLmodelChecker forms ks init
                 when nuXmv (do
                    putStrLn "[Creando archivo para nuXmv...]"
                    write_nuxmvLTL ks states init vars forms lforms [ranInit, ranNumInit, ranKS, ranF]
                    putStrLn "[Archivo creado]"
                    putStrLn "\n\tnuXmv:\n"
                    start        <- getCurrentTime
                    salida_nuXmv <- readProcess "/home/moy/nuXmv/bin/nuXmv" ["-dcx","ejemplo_random.smv"] []
                    end          <- getCurrentTime
                    let salida_nuXmv_forms = let tres_ ss = case ss of
                                                              [s1,s2,s3] -> ss
                                                              _:sss      -> tres_ sss in
                                             (concat . (map $ \s -> s++"\n") . tres_ . lines) salida_nuXmv
                    putStrLn salida_nuXmv_forms
                    putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start))
         LTLc -> let forms = sort $ randomFormsLTL lforms n ranF in
                 do
                  putStrLn $ "Forms: " ++ show forms ++ "\n"
                  call_LTLmodelChecker_CounterExample forms ks init
         CTL  -> let forms = sort $ randomFormsCTL lforms n ranF in
                 do
                  putStrLn $ "Forms: " ++ show forms ++ "\n"
                  call_CTLmodelChecker forms ks init


random_experiment::TypeExperiment->Int->Int->Bool->IO ()
random_experiment experiment n lforms nuXmv = do
   ranInit    <- randomIO
   ranNumInit <- randomIO
   ranKS      <- randomIO
   ranF       <- randomIO
   putStrLn $ " Semilla init: "    ++ show ranInit
   putStrLn $ " Semilla NumInit: " ++ show ranNumInit
   putStrLn $ " Semilla KS: "      ++ show ranKS
   putStrLn $ " Semilla F: "       ++ show ranF
   seeds_experiment experiment [ranInit, ranNumInit, ranKS, ranF] n lforms nuXmv


