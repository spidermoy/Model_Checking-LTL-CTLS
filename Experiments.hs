module Experiments where

import Data.List(sort, nub)
import Data.Set(singleton)
import System.Random(mkStdGen, randomIO, randoms, randomR, randomRs)
import Control.Monad(forM_, replicateM_, when)
import Data.Time(getCurrentTime, diffUTCTime)
import System.Process(readProcess)
import Control.Concurrent(forkIO, newEmptyMVar, putMVar, takeMVar)

import Core(
    Assertion(Assrt),
    KripkeS(KS),
    PathF(St),
    bot,
    evalMcALTL,
    mcALTLSet,
    mcALTLcSet,
    mcCTLSSet,
    nuXmvPath,
    smvOutput
  )
import RandomForms(
    randomFormsCTL,
    randomFormsLTL,
    securityG,
    vivacidadF,
    fmTimesX,
    progresoG,
    safeG,
    permGF,
    repeatG,
    altG,
    cicloCompletoG
  )
import RandomKS(randomKS, cycleKS)
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
    let suc_ks = randoms (mkStdGen ranKS)
        k      = fst $ randomR (1, 2^n) (mkStdGen ranNumInit)
        inits  = sort $ take k $ nub $ randomRs (0, 2^n - 1) (mkStdGen ranInit)
        states = [0 .. (2^n - 1)]
        ks     = randomKS n suc_ks
    putStrLn $ "\nKripke structure size: 2^" ++ show n
    putStrLn $ "Formulas depth: "            ++ show lforms
    putStrLn $ "Initial states number: "     ++ show k
    newEmptyMVar >>= run_experiment experiment vars inits states ks
  where
    run_experiment exp' vars inits states ks str =
      let forms = random_forms exp' in
      do
        print_forms forms
        when nuXmv (
            do
              putStrLn "\n[Writing nuXmv file...]"
              writeNuXmv ks states inits vars forms lforms (ranInit, ranNumInit, ranKS, ranF)
              putStrLn "[nuXmv file was written]\n"
          )
        print_type_experiment exp'
        start <- getCurrentTime
        callmc exp' forms ks inits str
        when (experiment /= LTLc) (replicateM_ 3 (takeMVar str >>= putStrLn))
        end <- getCurrentTime
        putStrLn $ "\n\tVerification time: " ++ show (diffUTCTime end start) ++ "\n"
        when nuXmv nuXmvExperiment
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


nuXmvExperiment::IO ()
nuXmvExperiment = do
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


ltlExperiment::String->Int->String->Int->Bool->IO ()
ltlExperiment ks_type n specification m nuXmv =
  if ks_type `elem` ["cycleKS", "randomKS"] && specification `elem` ["fmTimesX","securityG","vivacidadF","progresoG","safeG","permGF","repeatG","altG","cicloCompletoG"]
  then do
    putStrLn $ "\nEstructura de Kripke: " ++ ks_type ++ "(" ++ show n ++ ")"
    let (φ_m, descr) = ltl_experiment specification
    putStrLn $ "Experimento: " ++ let φ_m_s = show φ_m in
                                  if   m > 80
                                  then take 150 φ_m_s ++ "..."
                                  else φ_m_s
    putStrLn descr
    ks_n <- case ks_type of
      "cycleKS"  -> return $ cycleKS n
      "randomKS" -> randomKS n . randoms . mkStdGen <$> randomIO
      _          -> return $ KS (const [], \_ _ -> False)
    when nuXmv (do
        putStrLn "\n[Writing nuXmv file...]"
        writeNuXmv ks_n (if ks_type == "randomKS" then [0 .. (2^n - 1)] else [0 .. n-1]) [0] ["p" ++ show j | j <- [0 .. n-1]] (Left [φ_m]) m (0, 0, 0, 0)
        putStrLn "[nuXmv file was written]\n"
      )
    start <- getCurrentTime
    putStr "\n\tmcALTL: " >> print (evalMcALTL ks_n (Assrt (0, singleton φ_m)))
    end   <- getCurrentTime
    putStrLn $ "\n\tVerification time: " ++ show (diffUTCTime end start) ++ "\n"
    when nuXmv nuXmvExperiment
  else putStrLn "Tipo de KS no válido o experimento no válido"
  where
    ltl_experiment s = case s of
      "fmTimesX" -> (
          fmTimesX m,
          "\n\tF(p0∧X(p1∧X(p2∧…Xpm−1)))\n\n" ++
          "\tLa fórmula dice que eventualmente habrá una secuencia de 𝑚 estados consecutivos donde primero 𝑝0 es verdadero, seguido de 𝑝1, etc., hasta 𝑝𝑚−1.\n\n" ++
          "\tSi 𝑚≤𝑛 la fórmula puede satisfacerse en la estructura cíclica Mn.\n" ++
          "\tSi 𝑚>𝑛 la fórmula no puede satisfacerse en la estructura cíclica Mn."
        )
      "securityG" -> (
          securityG m,
          "\n\tG¬(p0∧p1∧…∧pm−1)\n\n" ++
          "\tPropiedad de seguridad (ausencia de ciertos estados):\n" ++
          "\tNunca habrá un estado donde todas las proposiciones 𝑝0,𝑝1,…,𝑝𝑚−1 sean verdaderas simultáneamente."
        )
      "vivacidadF" -> (
          vivacidadF m,
          "\n\tF(pn−1∧Xp0)\n\n" ++
          "\tPropiedad de vivacidad (alcanzabilidad de estados específicos):\n" ++
          "\tEventualmente se alcanzará el último estado etiquetado con 𝑝𝑛−1 seguido del primer estado etiquetado con 𝑝0."
        )
      "progresoG" -> (
          progresoG m,
          "\n\tφprog,n = G(p0→Fp1)∧G(p1→Fp2)∧…∧G(pn−2→Fpn−1)\n\n" ++
          "\tPropiedad de Progreso:\n" ++
          "\tInterpretación: Si 𝑝𝑖 es verdadero, eventualmente 𝑝𝑖+1 también será verdadero, para todos los 𝑖 en el rango de 0 a 𝑛−2\n" ++
          "\tUso: Verificar que hay un progreso secuencial en el sistema, es decir, que no se queda atrapado en un estado sin avanzar."
        )
      "safeG" -> (
          safeG m,
          "\n\tφsafe,m = G¬(q0∧X(q1∧X(…Xqm−1)))\n\n" ++
          "\tPropiedad de Ausencia de Secuencias Peligrosas:\n" ++
          "\tInterpretación: Nunca ocurre una secuencia de 𝑚 estados consecutivos donde primero 𝑞0 es verdadero, seguido de 𝑞1, y así sucesivamente hasta 𝑞𝑚−1.\n" ++
          "\tUso: Prevenir secuencias peligrosas o indeseadas de eventos en el sistema."
        )
      "permGF" -> (
          permGF m,
          "\n\tφperm,k = G(Fp0→G(p0∧X(p1∧X(…Xpk−1))))\n\n" ++
          "\tPropiedad de Permanencia:\n" ++
          "\tInterpretación: Si 𝑝0 es verdadero alguna vez, entonces siempre habrá una secuencia repetida de 𝑝0,𝑝1,…,𝑝𝑘−1.\n" ++
          "\tUso: Asegurar que una vez alcanzado un estado particular, se mantiene una secuencia estable de eventos."
        )
      "repeatG" -> (
          repeatG m,
          "\n\tφrepeat,n = G(p0→F(p1∧F(p2∧…Fpn−1)))\n\n" ++
          "\tPropiedad de Repetición Periódica:\n" ++
          "\tInterpretación: Si 𝑝0 es verdadero, entonces eventualmente ocurrirá 𝑝1, seguido de 𝑝2, y así sucesivamente hasta 𝑝𝑛−1, repetidamente.\n" ++
          "\tUso: Verificar que una secuencia de eventos ocurre de forma cíclica o periódica."
        )
      "altG" -> (
          altG m,
          "\n\tφalt,m = G(p0→(Fp1∨Fp2∨…∨Fpm−1))\n\n" ++
          "\tPropiedad de Alternancia:\n" ++
          "\tInterpretación: Si 𝑝0 es verdadero, eventualmente uno de 𝑝1,𝑝2,…,𝑝𝑚−1 será verdadero.\n" ++
          "\tUso: Especificar que después de un evento inicial, al menos una de varias opciones posibles debe ocurrir."
        )
      "cicloCompletoG" -> (
          cicloCompletoG m,
          "\n\tφcycle,n = G((p0∧Xp1∧…∧X^(n−1)pn−1)→X^np0\n\n" ++
          "\tPropiedad de Alternancia:\n" ++
          "\tInterpretación: Después de una secuencia completa de 𝑝0,𝑝1,…,𝑝𝑛−1, el ciclo se repite desde 𝑝0.\n" ++
          "\tUso: Modelar ciclos completos de eventos que se repiten indefinidamente."
        )
      _ -> (St bot, "")
