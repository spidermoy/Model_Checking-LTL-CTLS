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
           init                    = sort $ take k $ nub $ randomRs (0, 2^n - 1 :: Int) (mkStdGen ranInit)
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
                    write_nuxmv ks states init vars (Left forms) lforms [ranInit, ranNumInit, ranKS, ranF]
                    putStrLn "[Archivo creado]"
                    putStrLn "\n\tnuXmv:\n"
                    start        <- getCurrentTime
                    salida_nuXmv <- readProcess nuXmv_path ["-dcx",smv_output] []
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
                  putStrLn "\n\tmcALTLc:\n"
                  call_LTLmodelChecker_CounterExample forms ks init
                  when nuXmv (do
                    putStrLn "[Creando archivo para nuXmv...]"
                    write_nuxmv ks states init vars (Left forms) lforms [ranInit, ranNumInit, ranKS, ranF]
                    putStrLn "[Archivo creado]"
                    putStrLn "\n\tnuXmv:"
                    start        <- getCurrentTime
                    salida_nuXmv <- readProcess nuXmv_path [smv_output] []
                    end          <- getCurrentTime
                    let salida_nuXmv_forms = let nuXmv_out_lines = lines salida_nuXmv
                                                 nuXmv_out       = drop 26 nuXmv_out_lines in
                                             concat [l ++ "\n" | l <- nuXmv_out]
                    putStrLn salida_nuXmv_forms
                    putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start))
         CTL  -> let forms = sort $ randomFormsCTL lforms n ranF in
                 do
                  putStrLn $ "Forms: " ++ show forms
                  putStrLn "\n\tmcCTLS:\n"
                  call_CTLmodelChecker forms ks init
                  when nuXmv (do
                    putStrLn "[Creando archivo para nuXmv...]"
                    write_nuxmv ks states init vars (Right forms) lforms [ranInit, ranNumInit, ranKS, ranF]
                    putStrLn "[Archivo creado]"
                    putStrLn "\n\tnuXmv:\n"
                    start        <- getCurrentTime
                    salida_nuXmv <- readProcess nuXmv_path ["-dcx",smv_output] []
                    end          <- getCurrentTime
                    let salida_nuXmv_forms = let tres_ ss = case ss of
                                                              [s1,s2,s3] -> ss
                                                              _:sss      -> tres_ sss in
                                             (concat . (map $ \s -> s++"\n") . tres_ . lines) salida_nuXmv
                    putStrLn salida_nuXmv_forms
                    putStrLn $ "\tTiempo de verificación: " ++ (show $ diffUTCTime end start))


thesis_experiments::IO ()
thesis_experiments = do
    putStrLn "\n\tLTL EXPERIMENTS\n"
    putStrLn "1)"
    seeds_experiment LTL [-5053428644939494458, 5533791029784639153, -7168765502673159231, -7141886416844860059] 5 2 True
    putStrLn "2)"
    seeds_experiment LTL [7295322385161293443, 9119911361258526469, -3976311874439943576, -8020079916767466332] 7 3 True
    putStrLn "3)"
    seeds_experiment LTL [-4936023892743165299, 45022348244051710, -318369156885917136, 7664302682932608404] 7 2 True
    putStrLn "4)"
    seeds_experiment LTL [-2600085101192994995, 5103933280507166601, 7321885015983263168, -3980215730978928173] 9 3 True
    putStrLn "5)"
    seeds_experiment LTL [-76398304999172336, -8563057924574850918, 5654463647766606429, 3977323623621745794] 10 3 True
    putStrLn "6)"
    seeds_experiment LTL [2080258398381246525, -5652026877346931720, -6901248074493425579, -5647506115212334317] 11 3 True
    putStrLn "7)"
    seeds_experiment LTL [-462212670351055610, -6062112136505055477, -3474006495536599128, 7263318818191457324]  12 3 False
    putStrLn "8)"
    seeds_experiment LTL [1210007372340279273, 6577387527259573693, 7288838695625089897, 1550804476981824494] 13 4 False
    putStrLn "9)"
    seeds_experiment LTL [-5513877223295918523, -1129439877177454557, -1335035135597581770, -7224920461052687264] 14 5 False
    putStrLn "10)"
    seeds_experiment LTL [4245131971143730679, -5160046389823251879, -2541419881106205587, 7875966796276176735] 15 3 False
    putStrLn "11)"
    seeds_experiment LTL [-2317318845971560383, 63174928610846957, 7740644631840446483, 6914601918853315128] 17 3 False
    putStrLn "12)"
    seeds_experiment LTL [57632024823226759, 6995788245303145922, 7679432384484253856, -3512037660807785758] 18 3 False
    putStrLn "13)"
    seeds_experiment LTL [-444226188325987799, 902136017974027903, 6074936912016031953, -1716998379019504120] 19 3 False
    putStrLn "14)"
    seeds_experiment LTL [124380107722107864, -2021925931603360927, 6315226998243820130, -3066682603604533009] 20 3 False
    putStrLn "\tCTL EXPERIMENTS\n"
    putStrLn "1)"
    seeds_experiment CTL [5332018860263000951, -5659696516944381498, 6131573798985584345, 7270582556455303268] 5 3 True
    putStrLn "2)"
    seeds_experiment CTL [-3634750090013039070, -5400738926027436334, -4039355692805230431, -8152133867975338019] 7 3 True
    putStrLn "3)"
    seeds_experiment CTL [-6856179037350201869, -2206205337164536481, 410507466240855853, -1681413090854369932] 8 3 True
    putStrLn "4)"
    seeds_experiment CTL [8835624876428712241, 4848600760005918176, 8955329516851429801, -196645287117638075] 9 3 True
    putStrLn "5)"
    seeds_experiment CTL [9210208927398959434, 4419626295539301520, -8267301267196941026, 7796684326958031327] 10 3 True
    putStrLn "6)"
    seeds_experiment CTL [2380479831102832854, -6986691139666666669, 2195935036964894474, -8834836482381054136] 11 3 True
    putStrLn "7)"
    seeds_experiment CTL [2436629998256113239, -6923507982247632929, -4253175763147895628, -8973650143097053412] 12 3 True
    putStrLn "8)"
    seeds_experiment CTL [949953449846448731, -406275148541526948, -3842511025887463921, 4104264936417372307] 12 3 True
    putStrLn "9)"
    seeds_experiment CTL [100, 76, 4, 2] 12 2 True
    putStrLn "10)"
    seeds_experiment CTL [6237097947817666748, 7051789713999892797, 616016117592706892, 4966506196981833716] 13 2 True
    putStrLn "11)"
    seeds_experiment CTL [8666625547701607053, -970530960044127767, 3270900684283699943, -9112910988615369691] 15 2 False
    putStrLn "12)"
    seeds_experiment CTL [-5077824685923578894, 859138999552865391, 5683394313923832767, -7032287586481233253] 17 2 False
    putStrLn "13)"
    seeds_experiment CTL [7489358293504925504, -4212458674216479258, 2806816292527658512, -1650435001088151317] 18 2 False
    putStrLn "14)"
    seeds_experiment CTL [-3020335431298968450, -1085283208950323474, 7907697534437260499, 1709226432342667921] 19 2 False
    putStrLn "15)"
    seeds_experiment CTL [6830968738545262399, -7400582486838530919, -5225068410809829748, 4640882333315414212] 20 2 False






