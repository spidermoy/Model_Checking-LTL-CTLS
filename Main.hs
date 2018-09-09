module Main where
import Exp_LTL
import Exp_CTL
import System.Environment(getArgs)
import InputNuSMV


main = do 
        args <- getArgs;
        case args of
         ["random","LTL",n_vars,forms_n] -> experimento_random_LTL (read $ n_vars) (read $ forms_n) False
         ["random","nusmv","LTL",n_vars,forms_n] -> experimento_random_LTL (read $ n_vars) (read $ forms_n) True
         ["random","CTL",n_vars,forms_n] -> experimento_random_CTL (read $ n_vars) (read $ forms_n) False
         ["random","nusmv","CTL",n_vars,forms_n] -> experimento_random_CTL (read $ n_vars) (read $ forms_n) True
         ["seeds",ranInit,ranNumInit,ranKS,ranF,"LTL",n_vars,forms_n] -> experimento_seeds_LTL (map read [ranInit,ranNumInit,ranKS,ranF]) (read $ n_vars) (read $ forms_n) False
         ["seeds",ranInit,ranNumInit,ranKS,ranF,nusmv,"LTL",n_vars,forms_n] -> experimento_seeds_LTL (map read [ranInit,ranNumInit,ranKS,ranF]) (read $ n_vars) (read $ forms_n) True
         ["seeds",ranInit,ranNumInit,ranKS,ranF,"CTL",n_vars,forms_n] -> experimento_seeds_CTL (map read [ranInit,ranNumInit,ranKS,ranF]) (read $ n_vars) (read $ forms_n) False
         ["seeds",ranInit,ranNumInit,ranKS,ranF,nusmv,"CTL",n_vars,forms_n] -> experimento_seeds_CTL (map read [ranInit,ranNumInit,ranKS,ranF]) (read $ n_vars) (read $ forms_n) True
         ["tabla",n,"LTL"] -> tabla_LTL (read n);
         ["tabla",n,"CTL"] -> tabla_CTL (read n);
         ["input",file_path] -> experimento_input file_path
         _ -> putStrLn $ "Las opciones válidas son:\n\n" ++
                         "Para correr un experimento aleatorio LTL:\n"++
                         "\trandom LTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento aleatorio LTL y generar el archivo de nusmv:\n"++
                         "\trandom nusmv LTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento aleatorio CTL:\n"++
                         "\trandom CTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento aleatorio CTL y generar el archivo de nusmv:\n"++
                         "\trandom nusmv CTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento LTL con semillas generadoras:\n"++
                         "\tseeds ranInit ranNumInit ranKS ranF LTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento LTL con semillas generadoras y generar el archivo de nusmv:\n"++
                         "\tseeds ranInit ranNumInit ranKS ranF nusmv LTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento CTL con semillas generadoras:\n"++
                         "\tseeds ranInit ranNumInit ranKS ranF CTL 'num_vars' 'length_forms'\n"++
                         "Para correr un experimento CTL con semillas generadoras y generar el archivo de nusmv:\n"++
                         "\tseeds ranInit ranNumInit ranKS ranF nusmv CTL 'num_vars' 'length_forms'\n\n"++
                         "Para recibir un archivo de NuSMV como entrada:"++
                         "\tinput 'file_path'"
                         "donde 'num_vars'=número de variables del modelo\n      'length_forms'=la lóngitud de las fórmulas"++
                         "\n\nPara correr 'n' experimentos LTL de forma automática:\n"++
                         "\ttime ./Main tabla 'n' LTL"++
                         "\nPara correr 'n' experimentos CTL de forma automática:\n"++
                         "\ttime ./Main tabla 'n' CTL"++
                         "\n\nEjemplo:\n./Main random nusmv LTL 7 4"
                         
                         

         
         
         
         
         
             
