module Experiments where

import Data.List(sort, nub)
import System.Random(mkStdGen, randomIO, randoms, randomR, randomRs)
import Control.Monad(forM_, replicateM_, when)
import Data.Time(getCurrentTime, diffUTCTime)
import System.Process(readProcess)
import Control.Concurrent(forkIO, newEmptyMVar, putMVar, takeMVar)

import Core(
    KripkeS(KS),
    mcALTLSet,
    mcALTLcSet,
    mcCTLSSet,
    nuXmvPath,
    smvOutput
  )
import RandomForms(randomFormsLTL, randomFormsCTL)
import RandomKS(randomKS)
import ParserNuXmv(writeNuXmv)


data TypeExperiment = LTL | LTLc | CTL deriving Eq


randomExperiment::TypeExperiment->Int->Int->Bool->IO ()
randomExperiment experiment n lforms nuXmv = do
  ranInit    <- randomIO
  ranNumInit <- randomIO
  ranKS      <- randomIO
  ranF       <- randomIO
  putStrLn $ " init seed: "    ++ show ranInit
  putStrLn $ " NumInit seed: " ++ show ranNumInit
  putStrLn $ " KS seed: "      ++ show ranKS
  putStrLn $ " F seed: "       ++ show ranF
  seedsExperiment experiment (ranInit, ranNumInit, ranKS, ranF) n lforms nuXmv


seedsExperiment::TypeExperiment->(Int,Int,Int,Int)->Int->Int->Bool->IO ()
seedsExperiment experiment (ranInit, ranNumInit, ranKS, ranF) n lforms nuXmv =
  let vars = ["p" ++ show j | j <- [0 .. n-1]] in
  do
    let suc_ks    = randoms (mkStdGen ranKS) :: [Int]
        k         = fst $ randomR (1, 2^n) (mkStdGen ranNumInit)
        inits     = sort $ take k $ nub $ randomRs (0, 2^n - 1 :: Int) (mkStdGen ranInit)
        states    = [0 .. (2^n - 1)]
        ks@(KS _) = randomKS n suc_ks
    putStrLn $ "\nKripke structure size: 2^" ++ show n
    putStrLn $ "Formulas depth: "            ++ show lforms
    putStrLn $ "Initial states number: "     ++ show k
    str <- newEmptyMVar
    run_experiment experiment vars inits states ks str
  where
    run_experiment exp' vars inits states ks str =
      let forms = random_forms exp' in
      do
        print_forms forms
        when nuXmv (
            do
              putStrLn "\n[Writing nuXmv file...]"
              writeNuXmv ks states inits vars forms lforms (ranInit, ranNumInit, ranKS, ranF)
              putStrLn "[nuXmv file was written]"
          )
        print_type_experiment exp'
        start <- getCurrentTime
        callmc exp' forms ks inits str
        when (experiment /= LTLc) (replicateM_ 3 (takeMVar str >>= putStrLn))
        end <- getCurrentTime
        putStrLn $ "\n\tVerification time: " ++ show (diffUTCTime end start) ++ "\n"
        when nuXmv nuXmv_experiment
    print_forms (Left fs)  = putStrLn $ "Specifications: " ++ concatMap (("\n\t• "<>) . show) fs <> "\n"
    print_forms (Right fs) = putStrLn $ "Specifications: " ++ concatMap (("\n\t• "<>) . show) fs <> "\n"
    callmc experiment' forms ks inits str = case experiment' of
      LTL  -> let Left fs  = forms in
              forM_ fs $ \f -> forkIO $ putMVar str $ "-- specification " ++ show f ++ " : " ++ show (mcALTLSet ks inits f)
      LTLc -> let Left fs  = forms in
              forM_ fs (\f -> do
                  putStr $ "-- specification " ++ show f ++ " : "
                  mcALTLcSet ks inits f
               )
      CTL  -> let Right fs = forms in
              forM_ fs $ \f -> forkIO $ putMVar str $ "-- specification " ++ show f ++ " : " ++ show (mcCTLSSet (ks, inits) f)

    print_type_experiment exp' = case exp' of
      LTL  -> putStrLn "\n\tmcALTL:\n"
      LTLc -> putStrLn "\n\tmcALTLc:\n"
      CTL  -> putStrLn "\n\tmcCTL★:\n"
    random_forms exp' = case exp' of
      CTL -> Right $ sort $ randomFormsCTL lforms n ranF
      _   -> Left  $ sort $ randomFormsLTL lforms n ranF
    nuXmv_experiment = do
      putStrLn "\tnuXmv:"
      start        <- getCurrentTime
      salida_nuXmv <- readProcess nuXmvPath ["-dcx", smvOutput] []
      end          <- getCurrentTime
      let salida_nuXmv_forms = let nuXmv_out_lines = lines salida_nuXmv
                                   nuXmv_out       = drop 26 nuXmv_out_lines in
                               concat [l ++ "\n" | l <- nuXmv_out]
      putStrLn salida_nuXmv_forms
      putStrLn $ "\tVerification time: " ++ show (diffUTCTime end start)


thesisExperiments::IO ()
thesisExperiments = do
    putStrLn "\n\tLTL EXPERIMENTS\n"
    putStrLn "1)"
    seedsExperiment LTL (-5053428644939494458, 5533791029784639153, -7168765502673159231, -7141886416844860059) 5 2 True
    putStrLn "2)"
    seedsExperiment LTL (7295322385161293443, 9119911361258526469, -3976311874439943576, -8020079916767466332) 7 3 True
    putStrLn "3)"
    seedsExperiment LTL (-4936023892743165299, 45022348244051710, -318369156885917136, 7664302682932608404) 7 2 True
    putStrLn "4)"
    seedsExperiment LTL (-2600085101192994995, 5103933280507166601, 7321885015983263168, -3980215730978928173) 9 3 True
    putStrLn "5)"
    seedsExperiment LTL (-76398304999172336, -8563057924574850918, 5654463647766606429, 3977323623621745794) 10 3 True
    putStrLn "6)"
    seedsExperiment LTL (2080258398381246525, -5652026877346931720, -6901248074493425579, -5647506115212334317) 11 3 True
    putStrLn "7)"
    seedsExperiment LTL (-462212670351055610, -6062112136505055477, -3474006495536599128, 7263318818191457324)  12 3 False
    putStrLn "8)"
    seedsExperiment LTL (1210007372340279273, 6577387527259573693, 7288838695625089897, 1550804476981824494) 13 4 False
    putStrLn "9)"
    seedsExperiment LTL (-5513877223295918523, -1129439877177454557, -1335035135597581770, -7224920461052687264) 14 5 False
    putStrLn "10)"
    seedsExperiment LTL (4245131971143730679, -5160046389823251879, -2541419881106205587, 7875966796276176735) 15 3 False
    putStrLn "11)"
    seedsExperiment LTL (-2317318845971560383, 63174928610846957, 7740644631840446483, 6914601918853315128) 17 3 False
    putStrLn "12)"
    seedsExperiment LTL (57632024823226759, 6995788245303145922, 7679432384484253856, -3512037660807785758) 18 3 False
    putStrLn "13)"
    seedsExperiment LTL (-444226188325987799, 902136017974027903, 6074936912016031953, -1716998379019504120) 19 3 False
    putStrLn "14)"
    seedsExperiment LTL (124380107722107864, -2021925931603360927, 6315226998243820130, -3066682603604533009) 20 3 False
    putStrLn "\tCTL EXPERIMENTS\n"
    putStrLn "1)"
    seedsExperiment CTL (5332018860263000951, -5659696516944381498, 6131573798985584345, 7270582556455303268) 5 3 True
    putStrLn "2)"
    seedsExperiment CTL (-3634750090013039070, -5400738926027436334, -4039355692805230431, -8152133867975338019) 7 3 True
    putStrLn "3)"
    seedsExperiment CTL (-6856179037350201869, -2206205337164536481, 410507466240855853, -1681413090854369932) 8 3 True
    putStrLn "4)"
    seedsExperiment CTL (8835624876428712241, 4848600760005918176, 8955329516851429801, -196645287117638075) 9 3 True
    putStrLn "5)"
    seedsExperiment CTL (9210208927398959434, 4419626295539301520, -8267301267196941026, 7796684326958031327) 10 3 True
    putStrLn "6)"
    seedsExperiment CTL (2380479831102832854, -6986691139666666669, 2195935036964894474, -8834836482381054136) 11 3 True
    putStrLn "7)"
    seedsExperiment CTL (2436629998256113239, -6923507982247632929, -4253175763147895628, -8973650143097053412) 12 3 True
    putStrLn "8)"
    seedsExperiment CTL (949953449846448731, -406275148541526948, -3842511025887463921, 4104264936417372307) 12 3 True
    putStrLn "9)"
    seedsExperiment CTL (100, 76, 4, 2) 12 2 True
    putStrLn "10)"
    seedsExperiment CTL (6237097947817666748, 7051789713999892797, 616016117592706892, 4966506196981833716) 13 2 True
    putStrLn "11)"
    seedsExperiment CTL (8666625547701607053, -970530960044127767, 3270900684283699943, -9112910988615369691) 15 2 False
    putStrLn "12)"
    seedsExperiment CTL (-5077824685923578894, 859138999552865391, 5683394313923832767, -7032287586481233253) 17 2 False
    putStrLn "13)"
    seedsExperiment CTL (7489358293504925504, -4212458674216479258, 2806816292527658512, -1650435001088151317) 18 2 False
    putStrLn "14)"
    seedsExperiment CTL (-3020335431298968450, -1085283208950323474, 7907697534437260499, 1709226432342667921) 19 2 False
    putStrLn "15)"
    seedsExperiment CTL (6830968738545262399, -7400582486838530919, -5225068410809829748, 4640882333315414212) 20 2 False
