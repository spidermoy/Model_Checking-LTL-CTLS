module Core where
import Data.Set(Set,singleton,delete,insert,map,empty,elemAt,fromList,toList)
import Data.List(nub)

type At = String
type State = Int 

data KripkeS = KS (Int,State->[State],State->(At->Bool))


--Fórmulas de estado
data StateF = Var At | Neg At | ConjS StateF StateF | DisyS StateF StateF | A PathF | E PathF deriving (Eq,Ord) 


--Fórmulas de camino
data PathF = St StateF | DisyP PathF PathF | ConjP PathF PathF | U PathF PathF | R PathF PathF | X PathF deriving (Eq,Ord)

             

--Negación de fórmulas de estado
negS::StateF->StateF
negS φ = case φ of
          Var a -> Neg a
          Neg a -> Var a 
          ConjS φ₁ φ₂ -> DisyS (negS φ₁) (negS φ₂)
          DisyS φ₁ φ₂ -> ConjS (negS φ₁) (negS φ₂)
          A ф -> E $ negP ф
          E ф -> A $ negP ф
          
               
--Negación de fórmulas de camino
negP::PathF->PathF
negP ф = case ф of
          St φ -> St $ negS φ 
          ConjP ф₁ ф₂ -> DisyP (negP ф₁) (negP ф₂)
          DisyP ф₁ ф₂ -> ConjP (negP ф₁) (negP ф₂)
          X ф₁ -> X $ negP ф₁
          U ф₁ ф₂ -> R (negP ф₁) (negP ф₂)
          R ф₁ ф₂ -> U (negP ф₁) (negP ф₂)
              

--Abreviaturas de fórmulas
top = Neg ""
bot = Var ""

opG ф = case ф of
         R (St (Var "")) ф₁ -> opG ф₁
         U (St (Neg "")) (R (St (Var "")) ф₁) -> opF $ opG $ ф₁
         _ -> R (St bot) ф
         
opF ф = case ф of
         U (St (Neg "")) ф₁ -> opF ф₁
         R (St (Var "")) (U (St (Neg "")) ф₁) -> opG $ opF ф₁
         _ -> U (St top) ф  

         
impP ф₁ ф₂ = if ф₁==ф₂ then St top else DisyP (negP ф₁) ф₂
impS φ₁ φ₂ = if φ₁==φ₂ then top else DisyS (negS φ₁) φ₂


data Assertion = Assrt (State,Set PathF) deriving Eq


                                        
--Borra una fórmula de una aserción 
deleteF::PathF->Assertion->Assertion
deleteF ф (Assrt (s,_Φ)) = Assrt (s,delete ф _Φ)

--Inserta una fórmula en una aserción 
insertF::PathF->Assertion->Assertion
insertF ф (Assrt (s,_Φ)) = Assrt (s,insert ф _Φ)


--Submetas generadas por las reglas 
data Subgoals = T | Subg [Assertion] deriving Show

subgoalsA::KripkeS->Assertion->Subgoals
subgoalsA ks@(KS (_,r,_)) σ@(Assrt (s,_Φ)) = if _Φ == empty then Subg [] else 
                                             let ф = elemAt 0 _Φ in case ф of    
                                                    St φ -> if mcCTLS (ks,s) φ then T else Subg [deleteF ф σ]   
                                                    DisyP ф₁ ф₂ -> Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ]
                                                    ConjP ф₁ ф₂ -> if ф₁==ф₂ then Subg [insertF ф₁ $ deleteF ф σ] else   
                                                                  if ф₁ < ф₂ then Subg [insertF ф₁ $ deleteF ф σ,insertF ф₂ $ deleteF ф σ] 
                                                                  else Subg [insertF ф₂ $ deleteF ф σ,insertF ф₁ $ deleteF ф σ]
                                                    U ф₁ ф₂ -> if ф₁==ф₂ then Subg [insertF ф₁ $ deleteF ф σ] else
                                                             Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ,insertF ф₂ $ insertF (X ф) $ deleteF ф σ]                                                               
                                                    R ф₁ ф₂ -> if ф₁==ф₂ then Subg [insertF ф₁ $ deleteF ф σ] else
                                                             Subg [insertF ф₂ $ deleteF ф σ,insertF ф₁ $ insertF (X ф) $ deleteF ф σ] 
                                                    X _ -> let _Φ₁ = Data.Set.map (\(X ф) -> ф) _Φ in Subg [Assrt (s',_Φ₁) | s' <- r s]


check_success::[Assertion]->Bool
check_success v = let фs = (nub . concat) [toList _Φ | Assrt (_,_Φ)<-v] in
                  (not . null) [R ф₁ ф₂ | R ф₁ ф₂ <-фs, (not . elem ф₂) фs]  



--Verificador A-LTL basado únicamente en las reglas del artículo y equipado con una Stack para detectar ciclos                                                   
mcALTL::KripkeS->Assertion->Bool
mcALTL ks σ = dfs ks σ [] where
              dfs ks σ stack = if elem σ stack  
                               then check_success (σ : takeWhile (σ/=) stack)
                               else case subgoalsA ks σ of
                                     T -> True
                                     Subg σs -> case σs of
                                                 [] -> False
                                                 _ -> and [dfs ks σ₁ (σ:stack) | σ₁<-σs]                                               

                                    
--Verificador CTL* que extiende al verificador ALTL
mcCTLS::(KripkeS,State)->StateF->Bool
mcCTLS (ks@(KS (_,_,l)),s) φ = case φ of
                                Var a -> l s a
                                Neg a -> (not . l s) a
                                ConjS φ₁ φ₂ -> mcCTLS (ks,s) φ₁ && mcCTLS (ks,s) φ₂
                                DisyS φ₁ φ₂ -> mcCTLS (ks,s) φ₁ || mcCTLS (ks,s) φ₂
                                A ф -> mcALTL ks (Assrt (s,singleton ф)) 
                                E ф -> (not . mcALTL ks) (Assrt (s,(singleton . negP) ф))     
                                                                                         
   

--Actualiza los sucesores de un estado
upd_r::KripkeS->State->[State]->KripkeS
upd_r (KS (n,r,l)) s ss = KS (n,\s' -> if s'==s then ss else r s',l) 
               
               
--Verificador LTL que recibe un conjunto de estados iniciales
mcALTL_set::KripkeS->[State]->PathF->Bool
mcALTL_set ks ss ф = and [mcALTL ks (Assrt (s,singleton ф)) | s <- ss] --let ks' = upd_r ks (-1) ss in mcALTL ks' (Assrt (-1,singleton $ X ф))


--Verificador CTL* que recibe un conjunto de estados iniciales
mcCTLS_set::(KripkeS,[State])->StateF->Bool
mcCTLS_set (ks,ss) φ = and [mcCTLS (ks,s) φ | s <- ss] --let ks' = upd_r ks (-1) ss in mcCTLS (ks',-1) (A $ X $ St φ)


{-====================================================================================-}


instance Show Assertion where
   show (Assrt (s,_Φ)) = "s"++show s++"⊢"++(show $ toList _Φ)
   

instance Show StateF where
   show sf = case sf of
             --Literales
             Var "" -> "⊥"
             Var a -> a
             Neg "" -> "┬"
             Neg a -> "¬"++a
             --Conjunción
             ConjS (Var p) (Var q) -> p++"∧"++q
             ConjS (Neg p) (Neg q) -> "¬"++p++"∧¬"++q
             ConjS s1 (Var q) -> case s1 of
                                    Neg p -> show s1++"∧"++q
                                    _ -> "("++show s1++")∧"++q
             ConjS (Var p) s2 -> case s2 of
                                    Neg q -> p++"∧¬"++q  
                                    _ -> p++"∧("++show s2++")"
             ConjS s1@(Neg p) s2 -> show s1++"∧("++show s2++")"    
             ConjS s1 s2@(Neg q) -> "("++show s1++")∧"++show s2                    
             ConjS s1 s2 -> "("++show s1++")∧("++show s2++")"     
             --Disyunción                    
             DisyS (Var p) (Var q) -> p++"∨"++q
             DisyS (Neg p) (Neg q) -> "¬"++p++"∨¬"++q
             DisyS s1 (Var q) -> case s1 of
                                    Neg p -> show s1++"∨"++q
                                    _ -> "("++show s1++")∨"++q
             DisyS (Var p) s2 -> case s2 of
                                    Neg q -> p++"∨¬"++q  
                                    _ -> p++"∨("++show s2++")"
             DisyS s1@(Neg p) s2 -> show s1++"∨("++show s2++")"    
             DisyS s1 s2@(Neg q) -> "("++show s1++")∨"++show s2                    
             DisyS s1 s2 -> "("++show s1++")∨("++show s2++")" 
             --Cuantificador A
             A p -> case p of
                     X p' -> "AX "++show p'  
                     U (St (Neg "")) p' -> "AF "++show p'
                     R (St (Var "")) p' -> "AG "++show p'     
                     _ -> "A["++show p++"]"
             E p -> case p of
                     X p' -> "EX "++show p'   
                     U (St (Neg "")) p' -> "EF "++show p'
                     R (St (Var "")) p' -> "EG "++show p'      
                     _ -> "E["++show p++"]"


instance Show PathF where
   show p = case p of
             --Fórmulas de estado
             St s -> case s of 
                     Var _ -> show s
                     Neg _ -> show s
                     _ -> "("++show s++")"
             --Conjunción
             ConjP p1@(St _) p2@(St _) -> show p1++"∧"++show p2     
             ConjP p1@(St _) p2 -> show p1++"∧("++show p2++")"    
             ConjP p1 p2@(St _) -> "("++show p1++")∧"++show p2                                
             ConjP p1 p2 -> "("++show p1++")∧("++show p2++")"
             --Disyunción
             DisyP p1@(St _) p2@(St _) -> show p1++"∨"++show p2     
             DisyP p1@(St _) p2 -> show p1++"∨("++show p2++")"    
             DisyP p1 p2@(St _) -> "("++show p1++")∨"++show p2                                
             DisyP p1 p2 -> "("++show p1++")∨("++show p2++")"                                            
             --neXt state
             X q -> case q of
                     St s -> "X"++show s
                     X q1 -> "X"++show q
                     _ -> "X("++show q++")"              
             --Until
             U (St (Neg "")) p2@(St _) -> "F"++show p2
             U (St (Neg "")) p2 -> "F("++show p2++")"
             U p1@(St _) p2@(St _) -> show p1++"U"++show p2     
             U p1@(St _) p2 -> show p1++"U("++show p2++")"    
             U p1 p2@(St _) -> "("++show p1++")U"++show p2                                
             U p1 p2 -> "("++show p1++")U("++show p2++")" 
             --release
             R (St (Var "")) p2@(St _) -> "G"++show p2
             R (St (Var "")) p2 -> "G("++show p2++")"
             R p1@(St _) p2@(St _) -> show p1++"R"++show p2       
             R p1@(St _) p2 -> show p1++"R("++show p2++")"    
             R p1 p2@(St _) -> "("++show p1++")R"++show p2                                
             R p1 p2 -> "("++show p1++")R("++show p2++")"


