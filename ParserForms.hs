module ParserForms where
import Core


pathFormsToFile::[PathF]->String
pathFormsToFile forms = case forms of
                         [] -> "\n\n"
                         f:fs -> "LTLSPEC\n"++traduceP f++"\n\n"++pathFormsToFile fs  
                              
traduceP::PathF->String
traduceP f = case f of
              St sf -> traduceS sf 
              DisyP f1 f2 -> "("++traduceP f1 ++") | ("++ traduceP f2++")"
              ConjP f1 f2 -> "("++ traduceP f1 ++") & ("++ traduceP f2++")"
              U f1 f2 -> if f1 ==(St top) then "F("++ traduceP f2++")" else "("++traduceP f1 ++") U ("++ traduceP f2++")"
              R f1 f2 -> if f1 ==(St bot) then "G("++ traduceP f2++")" else "("++traduceP f1 ++") V ("++ traduceP f2++")" 
              X f1 -> "X("++ traduceP f1++")"
                              
                              
stateFormsToFile::[StateF]->String
stateFormsToFile forms = case forms of
                               [] -> "\n\n"
                               f:fs -> "CTLSPEC\n"++traduceS f++"\n\n"++stateFormsToFile fs 
                               
traduceS::StateF->String                  
traduceS f = case f of
              Var "" -> "FALSE"
              Var p -> p   
              Neg "" -> "TRUE"
              Neg p -> "!"++p   
              ConjS f1 f2 -> "("++ traduceS f1 ++") & ("++ traduceS f2++")"
              DisyS f1 f2 -> "("++ traduceS f1 ++") | ("++ traduceS f2++")"
              A pf -> "A"++case pf of
                           X _ ->traduceP pf
                           U f1 f2 -> if f1==(St top) then "F ("++traduceP f2++")" else "["++traduceP f1++" U "++traduceP f2++"]" 
                           R _ f2 -> "G ("++traduceP f2++")"   
              E pf -> "E"++case pf of
                           X _ ->traduceP pf
                           U f1 f2 -> if f1==(St top) then "F ("++traduceP f2++")" else "["++traduceP f1++" U "++traduceP f2++"]" 
                           R _ f2 -> "G ("++traduceP f2++")" 
                                         
                                         
                                         
