module Binarios where

sucB::[Bool]->[Bool]
sucB [] = [True]
sucB (False:bs) = True:bs 
sucB (True:bs) = False : sucB bs


bins::[[Bool]]
bins = [False] : nexts bins 
           where nexts (b:bs) = (sucB b) : nexts bs 
           
           
completaCeros::Int->[Bool]->[Bool]
completaCeros n bs = let m = length bs in
                     if m < n then bs++(replicate (n-m) False) else bs  
                     
                     
statesbin::Int->[[Bool]]
statesbin n = (map (completaCeros n) $ take (2^n) bins)
                     
                              

