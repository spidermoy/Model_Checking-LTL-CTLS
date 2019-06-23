{-
 ****************************
 * LTL & CTL MODEL CHECKING *
 **************************** -}


module Core where

import Data.Set(Set, singleton, delete, insert, map, empty, elemAt, fromList, toList, member)
import Data.List(nub)
import Control.Monad(when, forM_)
import Control.Exception
import StateMonad


-- Atomic formulas (variables) are strings.
type At = String

-- States in Kripke structures are integers.
type State = Int 

{-
A Kripke Structure is a triple (n, r, l). 'n' indicates the states range [0 .. n].
'r' is the transition function and 'l' maps states to variable sets.
-}
data KripkeS = KS (Int, State->[State], State->(At->Bool))

-- State formulas.
data StateF = Var At
            | Neg At
            | ConjS StateF StateF
            | DisyS StateF StateF
            | A PathF
            | E PathF deriving (Eq,Ord)

-- Path formulas.
data PathF = St StateF 
           | DisyP PathF PathF 
           | ConjP PathF PathF 
           | U PathF PathF 
           | R PathF PathF 
           | X PathF deriving (Eq,Ord)


--Recursive Normal Negative Form of state and path formulas.
negS::StateF->StateF
negS φ = case φ of
          Var a      -> Neg a
          Neg a      -> Var a 
          ConjS φ₁ φ₂  -> DisyS (negS φ₁) (negS φ₂)
          DisyS φ₁ φ₂  -> ConjS (negS φ₁) (negS φ₂)
          A ф        -> E $ negP ф
          E ф        -> A $ negP ф

negP::PathF->PathF
negP ф = case ф of
           St φ      -> St $ negS φ 
           ConjP ф₁ ф₂ -> DisyP (negP ф₁) (negP ф₂)
           DisyP ф₁ ф₂ -> ConjP (negP ф₁) (negP ф₂)
           X ф₁             -> X $ negP ф₁
           U ф₁ ф₂         -> R (negP ф₁) (negP ф₂)
           R ф₁ ф₂         -> U (negP ф₁) (negP ф₂)

-- Bot and Top
bot::StateF
bot = Var ""

top::StateF
top = Neg ""

-- Gф and Fф 
opG::PathF->PathF
opG ф = case ф of
         -- GGф ≡ Gф
         R (St (Var "")) ф₁ -> opG ф₁
         -- GFGф ≡ FGф
         U (St (Neg "")) (R (St (Var "")) ф₁) -> opF $ opG $ ф₁
         _ -> R (St bot) ф

opF::PathF->PathF
opF ф = case ф of
          -- FFф ≡ Fф
          U (St (Neg "")) ф₁                                      -> opF ф₁
          -- FGFф ≡ GFф
          R (St (Var "")) (U (St (Neg "")) ф₁) -> opG $ opF ф₁
          _                                    -> U (St top) ф

-- Implication Operator
impS::StateF->StateF->StateF
impS φ₁ φ₂ = if φ₁ == φ₂
           then top
           else DisyS (negS φ₁) φ₂

impP::PathF->PathF->PathF
impP ф₁ ф₂ = if ф₁ == ф₂ 
           then St top
           else DisyP (negP ф₁) ф₂


data Assertion = Assrt (State, Set PathF) deriving (Eq, Ord)

--Borra una fórmula de una aserción 
deleteF::PathF->Assertion->Assertion
deleteF ф (Assrt (s,_Φ)) = Assrt (s,delete ф _Φ)

--Inserta una fórmula en una aserción 
insertF::PathF->Assertion->Assertion
insertF ф (Assrt (s, _Φ)) = Assrt (s, insert ф _Φ)


subgoals::KripkeS->Assertion->Subgoals
subgoals ks@(KS (_, r, _)) σ@(Assrt (s, _Φ)) =
   if _Φ == empty
   then Subg []
   else let ф = elemAt 0 _Φ in
        case ф of
          St φ       -> if eval_mcCTLS ks (s, φ)
                        then T 
                        else Subg [deleteF ф σ]
          DisyP ф₁ ф₂  -> Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ]
          ConjP ф₁ ф₂  -> if ф₁ == ф₂ -- ф∧ф ≡ ф
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        else Subg [insertF ф₁ $ deleteF ф σ,
                                   insertF ф₂ $ deleteF ф σ]
          U ф₁ ф₂         -> if ф₁ == ф₂ -- фUф ≡ ф 
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        -- ф₁Uф₂ ≡ (ф₁∨ф₂)∧(ф₂∨(X(ф₁Uф₂)))
                        else Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ,
                                   insertF ф₂ $ insertF (X ф) $ deleteF ф σ]
          R ф₁ ф₂         -> if ф₁ == ф₂ -- фRф ≡ ф
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        -- ф₁Rф₂ ≡ ф₂∧(ф₁∨(X(ф₁Rф₂)))
                        else Subg $ if ф₁ == St bot
                                    then [insertF ф₂ $ deleteF ф σ,
                                          insertF (X ф) $ deleteF ф σ]
                                    else [insertF ф₂ $ deleteF ф σ,
                                          insertF ф₁ $ insertF (X ф) $ deleteF ф σ]
          X _        -> -- (Xф₁)∨(Xф₂)∨⋯∨(Xф_n) ≡ X(ф₁∨ф₂∨⋯∨ф_n)
                        let _Φ₁ = Data.Set.map (\(X ф) -> ф) _Φ in
                        Subg [Assrt (s', _Φ₁) | s' <- r s]


--Submetas generadas por las reglas
data Subgoals = T | Subg [Assertion]


check_success::[Assertion]->Bool
check_success v = let фs = concat [toList _Φ | Assrt (_, _Φ) <- v] in
                  (not . null) [R ф₁ ф₂ | R ф₁ ф₂  <- фs, (not . elem ф₂) фs]

--Actualiza los sucesores de un estado
upd_r::KripkeS->State->[State]->KripkeS
upd_r (KS (n, r, l)) s ss = KS (n, \s' -> if s'==s then ss else r s', l)


type Vp = Set Assertion

elem_Vp::Assertion->StateM Vp Bool
elem_Vp σ = ST $ \v -> (member σ v, v)

insert_Vp::Assertion->StateM Vp ()
insert_Vp σ = ST $ \v -> ((), insert σ v)


mcALTL::KripkeS->Assertion->StateM Vp Bool
mcALTL ks σ = dfs ks σ [] 
   where
     dfs::KripkeS->Assertion->[Assertion]->StateM Vp Bool
     dfs ks σ stack = do
         σ_in_Vp <- elem_Vp σ
         if   σ_in_Vp
         then return True
         else if   elem σ stack
              then do
                    let stack' = σ : takeWhile (σ/=) stack
                        b      = check_success stack'
                    when b (forM_ stack' insert_Vp)
                    return b
              else case subgoals ks σ of
                     T       -> do
                                 insert_Vp σ
                                 return True
                     Subg σs -> case σs of
                                  [] -> return False
                                  _  -> do
                                         bs <- sequence [dfs ks σ₁ (σ:stack) | σ₁ <- σs]
                                         return (and bs)


eval_mcALTL::KripkeS->Assertion->Bool
eval_mcALTL ks σ = evalStateM (mcALTL ks σ) empty

mcALTL_set::KripkeS->[State]->PathF->Bool
mcALTL_set ks ss ф = let ks' = upd_r ks (-1) ss in
                     eval_mcALTL ks' (Assrt (-1, singleton $ X ф))


type Vs = Set (State,StateF)

elem_Vs::(State,StateF)->StateM Vs Bool
elem_Vs p = ST $ \v -> (member p v, v)

insert_Vs::(State,StateF)->StateM Vs ()
insert_Vs p = ST $ \v -> ((), insert p v)


mcCTLS::KripkeS->(State, StateF)->StateM Vs Bool
mcCTLS ks@(KS (_, _, l)) (s, φ) = 
   do
    s_φ_in_Vs <- elem_Vs (s, φ)
    if s_φ_in_Vs 
    then return True
    else case φ of
           Var a      -> update (l s a)
           Neg a      -> update ((not . l s) a)
           ConjS φ₁ φ₂  -> do
                          b₁ <- mcCTLS ks (s, φ₁)
                          b₂ <- mcCTLS ks (s, φ₂)
                          update (b₁ && b₂)
           DisyS φ₁ φ₂  -> do
                          b₁ <- mcCTLS ks (s, φ₁)
                          b₂ <- mcCTLS ks (s, φ₂)
                          update (b₁ || b₂)
           A ф        -> update (eval_mcALTL ks (Assrt (s, singleton ф)))
           E ф        -> update ((not . eval_mcALTL ks) (Assrt (s, (singleton . negP) ф)))
   where
     update b = do
                 when b (insert_Vs (s, φ))
                 return b


eval_mcCTLS::KripkeS->(State, StateF)->Bool
eval_mcCTLS ks (s, φ) = evalStateM (mcCTLS ks (s, φ)) empty

mcCTLS_set::(KripkeS,[State])->StateF->Bool
mcCTLS_set (ks,ss) φ = let ks' = upd_r ks (-1) ss in
                       eval_mcCTLS ks' (-1, (A . X) $ St φ)

{- 
 *********************************************************
 * LTL, LTL WITH COUNTEREXAMPLES AND CTL☆ MODEL CHECKING *
 ********************************************************* -}

mcALTLc::KripkeS->Assertion->StateM Vp Bool
mcALTLc ks σ = dfs ks σ []
   where
     dfs::KripkeS->Assertion->[Assertion]->StateM Vp Bool
     dfs ks σ stack = do
         σ_in_Vp <- elem_Vp σ
         if σ_in_Vp
         then return True
         else if elem σ stack
              then do
                    let stack' = σ : takeWhile (σ/=) stack
                    if check_success stack'
                    then do
                          forM_ stack' insert_Vp
                          return True
                    else cycleC (σ:stack)
              else case subgoals ks σ of
                     T       -> do
                                 insert_Vp σ
                                 return True
                     Subg σs -> case σs of
                                  [] -> finiteC stack
                                  _  -> do
                                         bs <- sequence [dfs ks σ₁ (σ:stack) | σ₁ <- σs]
                                         return (and bs)
     finiteC ((Assrt (s, _Φ)):stack) = error $ "\n\n\tFinite counterexample:\n\n" ++
                                               "s" ++ show s ++ " ⊬ " ++ (show $ toList _Φ) ++ "\n" 
                                               ++ concat [show σ ++ "\n" | σ <- filter (\(Assrt (s, _)) -> s >= 0) stack]
     cycleC (σ:stack)                = error $ "\n\n\tU-Cycle detected:\n\n" ++
                                       concat [if σ_ == σ
                                               then "--> " ++ show σ_ ++ "\n"
                                               else "    " ++ show σ_ ++ "\n" | σ_ <- filter (\(Assrt (s, _)) -> s >= 0) (σ:stack)]


eval_mcALTLc::KripkeS->Assertion->IO ()
eval_mcALTLc ks σ = catch
                      (print $ evalStateM (mcALTLc ks σ) empty)
                      (\(ErrorCall counterexampleP) -> putStrLn counterexampleP)


mcALTLc_set::KripkeS->[State]->PathF->IO ()
mcALTLc_set ks ss ф = let ks' = upd_r ks (-1) ss in
                      eval_mcALTLc ks' (Assrt (-1, singleton $ X ф))


{- 
 ********************
 * LTL MODEL UPDATE *
 ******************** -}

powerset::[a]->[[a]]
powerset []     = [[]]
powerset (x:xs) = let xss = powerset xs in
                  xss ++ [x:xs | xs <- xss]


upd1ALTL::KripkeS->Assertion->[KripkeS]
upd1ALTL ks σ = [m' | m' <- nub $ evalStateM (dfs ks σ []) empty, eval_mcALTL m' σ]
   where
     dfs::KripkeS->Assertion->[Assertion]->StateM Vp [KripkeS]
     dfs ks@(KS (n_sts,_,l)) σ@(Assrt (s,_Φ)) stack =
       do
        if   null _Φ
        then return []
        else do
        let ф = elemAt 0 _Φ
        σ_in_Vp <- elem_Vp σ
        if σ_in_Vp
        then do
              return [ks]
        else if elem σ stack
             then do
                   let stack' = σ : takeWhile (σ/=) stack
                   if check_success stack'
                   then do
                         forM_ stack' insert_Vp
                         return [ks]
                   else dfs ks (deleteF ф σ) (σ:stack)
             else case ф of
                         St (Var a) -> if l s a
                                       then do
                                             insert_Vp σ
                                             return [ks]
                                       else dfs ks (deleteF ф σ) (σ:stack)
                         St (Neg a) -> if (not $ l s a)
                                       then do
                                             insert_Vp σ
                                             return [ks]
                                       else dfs ks (deleteF ф σ) (σ:stack)
                         DisyP ф₁ ф₂  -> dfs ks (insertF ф₁ $
                                               insertF ф₂ $
                                               deleteF ф σ) (σ:stack)
                         ConjP ф₁ ф₂  -> do
                                        k'  <- dfs ks (insertF ф₁ $ 
                                                       deleteF ф σ) (σ:stack)
                                        k'' <- sequence [dfs k₁ (insertF ф₂ $ 
                                                                deleteF ф σ) (σ:stack) | k₁ <- k']
                                        return $ concat k''
                         U ф₁ ф₂         -> do
                                        k'  <- dfs ks (insertF ф₁ $
                                                       insertF ф₂ $
                                                       deleteF ф σ) (σ:stack)
                                        k'' <- sequence [dfs k₁ (insertF ф₂        $
                                                                insertF (X ф) $
                                                                deleteF ф σ) (σ:stack) | k₁ <- k']
                                        return $ concat k''
                         R ф₁ ф₂         -> do
                                        k'  <- dfs ks (insertF ф₂ $ 
                                                       deleteF ф σ) (σ:stack)
                                        k'' <- sequence [dfs k₁ (insertF ф₁        $
                                                                insertF (X ф) $
                                                                deleteF ф σ) (σ:stack) | k₁ <- k']
                                        return $ concat k''
                         X _        -> xUpdALTL (tail $ powerset [0 .. n_sts]) 
                                                               (Data.Set.map (\(X ф) -> ф) _Φ)
                             where
                               xUpdALTL nexts _Φ = do
                                   kss <- sequence [updNextALTL (upd_r ks s ns) ns _Φ | ns <- nexts]
                                   return $ concat kss
                               updNextALTL ks ns _Φ = do
                                      kss <- sequence [dfs ks (Assrt (s', _Φ)) (σ:stack) | s' <- ns]
                                      return $ concat kss


{-====================================================================================-}
{- 
 *********************
 * EXAMPLES AND TEST *
 ********************* -}

m = KS (2,r,l)
   where
     r s = case s of
             0 -> [1,2]
             1 -> [0,2]
             2 -> [2]
     l s = case s of
             0 -> \a -> case a of 
                          "p" -> True
                          "q" -> True
                          _   -> False
             1 -> \a -> case a of
                          "q" -> True
                          "r" -> True
                          _   -> False
             2 -> \a -> case a of
                          "r" -> True
                          _   -> False
                          

{- counterexamples -}

-- LTL

ltl1 = eval_mcALTLc m (Assrt (0, singleton $ ConjP (St $ Var "p") (St $ Var "q")))
ltl2 = eval_mcALTLc m (Assrt (0, singleton $ St $ Neg "r"))
ltl3 = eval_mcALTLc m (Assrt (0, singleton $ St $ top))
ltl4 = mcALTLc_set m [0] $ X $ St $ Var "r"
ltl5 = mcALTLc_set m [0] $ X $ ConjP (St $ Var "q") (St $ Var "r")
ltl6 = eval_mcALTLc m (Assrt (0, singleton $ opG $ negP $ ConjP (St $ Var "p") (St $ Var "r")))
ltl7 = eval_mcALTLc m (Assrt (2, singleton $ opG $  St $ Var "r"))
ltl8 = mcALTLc_set m [0, 1, 2] $ impP (opF $ ConjP (St $ Neg "q") (St $ Var "r")) (opF $ opG $ St $ Var "r")
ltl9 = eval_mcALTLc m (Assrt (0, singleton $ opG $ opF $ St $ Var "p"))
ltl10_1 = eval_mcALTLc m (Assrt (0, singleton $ impP (opG $ opF $ St $ Var "p") (opG $ opF $ St $ Var "r")))
ltl10_2 = eval_mcALTLc m (Assrt (0, singleton $ impP (opG $ opF $ St $ Var "r") (opG $ opF $ St $ Var "p")))


{- model update -}

xupd00 = upd1ALTL m (Assrt (0, singleton $ (X $ St $ Var "p")))
xupd01 = upd1ALTL m (Assrt (0, singleton $ (X $ St $ Var "q")))
xupd02 = upd1ALTL m (Assrt (0, singleton $ (X $ St $ Var "r")))

xupd10 = upd1ALTL m (Assrt (1, singleton $ (X $ St $ Var "p")))
xupd11 = upd1ALTL m (Assrt (1, singleton $ (X $ St $ Var "q")))
xupd12 = upd1ALTL m (Assrt (1, singleton $ (X $ St $ Var "r")))

xupd20 = upd1ALTL m (Assrt (2, singleton $ (X $ St $ Var "p")))
xupd21 = upd1ALTL m (Assrt (2, singleton $ (X $ St $ Var "q")))
xupd22 = upd1ALTL m (Assrt (2, singleton $ (X $ St $ Var "r")))

ejemUpdLTL00  = upd1ALTL m (Assrt (0, singleton $ (opG $ opF $ St $ Var "p")))
ejemUpdLTL01  = upd1ALTL m (Assrt (1, singleton $ (opG $ opF $ St $ Var "p")))
ejemUpdLTL02  = upd1ALTL m (Assrt (2, singleton $ (opG $ opF $ St $ Var "p")))

ejemUpdLTL10  = upd1ALTL m (Assrt (0, singleton $ (opG $ opF $ St $ Var "q")))
ejemUpdLTL11  = upd1ALTL m (Assrt (1, singleton $ (opG $ opF $ St $ Var "q")))
ejemUpdLTL12  = upd1ALTL m (Assrt (2, singleton $ (opG $ opF $ St $ Var "q")))

ejemUpdLTL20  = upd1ALTL m (Assrt (0, singleton $ (opG $ opF $ St $ Var "r")))
ejemUpdLTL21  = upd1ALTL m (Assrt (1, singleton $ (opG $ opF $ St $ Var "r")))
ejemUpdLTL22  = upd1ALTL m (Assrt (2, singleton $ (opG $ opF $ St $ Var "r")))

ejemUpdLTL30 = upd1ALTL m (Assrt (0, singleton $ (opF $ opG $ St $ Var "p")))
ejemUpdLTL31 = upd1ALTL m (Assrt (1, singleton $ (opF $ opG $ St $ Var "p")))
ejemUpdLTL32 = upd1ALTL m (Assrt (2, singleton $ (opF $ opG $ St $ Var "p")))

ejemUpdLTL40  = upd1ALTL m (Assrt (0, singleton $ (opF $ opG $ St $ Var "q")))
ejemUpdLTL41  = upd1ALTL m (Assrt (1, singleton $ (opF $ opG $ St $ Var "q")))
ejemUpdLTL42  = upd1ALTL m (Assrt (2, singleton $ (opF $ opG $ St $ Var "q")))

ejemUpdLTL50  = upd1ALTL m (Assrt (0, singleton $ (opF $ opG $ St $ Var "r")))
ejemUpdLTL51  = upd1ALTL m (Assrt (1, singleton $ (opF $ opG $ St $ Var "r")))
ejemUpdLTL52  = upd1ALTL m (Assrt (2, singleton $ (opF $ opG $ St $ Var "r")))

ejemUpdLTL10_1  = upd1ALTL m (Assrt (0, singleton $ impP (opG $ opF $ St $ Var "p") (opG $ opF $ St $ Var "r")))
ejemUpdLTL10_2  = upd1ALTL m (Assrt (0, singleton $ impP (opG $ opF $ St $ Var "r") (opG $ opF $ St $ Var "p")))

{-====================================================================================-}

{- 
 ******************
 * DATA INSTANCES *
 ****************** -}

--showL::Int->String
showL n = [filter ("" /=) $
           fmap (\(i, state) -> if state 
                                then "p" ++ show i
                                else "") $ zip [0 .. n-1] state | state <- statesbin n]


instance Show KripkeS where
   show (KS (n, r, l)) = "{" ++ 
                     concat ["\nR s" ++ show s ++ " ↦ " ++ (show $ r s) | s <- [0 .. n]] ++ "\n" ++
                         "}\n"


statesbin::Int->[[Bool]]
statesbin n = fmap (completeZeros n) $ take (2^n) bins
   where
      bins = [False] : nexts bins 
      nexts (b:bs) = (sucB b) : nexts bs
      sucB []         = [True]
      sucB (False:bs) = True:bs 
      sucB (True:bs)  = False : sucB bs
      completeZeros n bs = let m = length bs in
                           if m < n 
                           then bs++(replicate (n-m) False) 
                           else bs

showKS::KripkeS->String
showKS (KS (n, r, l)) = let records = showL (round $ logBase 2 (fromIntegral n) :: Int) in
                         "{" ++ 
                           concat ["\nR s" ++ show s ++ " ↦ " ++ (show $ r s) ++ "\n" ++
                                     "L s" ++ show s ++ " ↦ " ++ (show $ records !! s) ++ "\n"
                                                                                | s <- [0 .. n]] ++
                         "}\n"


instance Eq KripkeS where
      (==) (KS (n, r1, _)) (KS (_, r2, _)) = [r1 s | s <- [0 .. n]] == [r2 s | s <- [0 .. n]]


instance Show Assertion where
   show (Assrt (s,_Φ)) = "s" ++ show s ++ " ⊢ " ++ (show $ toList _Φ)


instance Show StateF where
   show sf = case sf of
             -- Variables
              Var "" -> "⊥"
              Var a -> a
              Neg "" -> "┬"
              Neg a -> "¬"++a
             -- Conjunction
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
             -- Disjunction
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
             -- ForAll
              A p -> case p of
                      X p' -> "AX "++show p'
                      U (St (Neg "")) p' -> "AF "++show p'
                      R (St (Var "")) p' -> "AG "++show p'
                      _ -> "A["++show p++"]"
             -- Exists
              E p -> case p of
                      X p' -> "EX "++show p'
                      U (St (Neg "")) p' -> "EF "++show p'
                      R (St (Var "")) p' -> "EG "++show p'
                      _ -> "E["++show p++"]"


instance Show PathF where
   show p = case p of
             -- State Formulas
             St s -> case s of
                     Var _ -> show s
                     Neg _ -> show s
                     _ -> "("++show s++")"
             -- Conjunction
             ConjP p1@(St _) p2@(St _) -> show p1++"∧"++show p2
             ConjP p1@(St _) p2 -> show p1++"∧("++show p2++")"
             ConjP p1 p2@(St _) -> "("++show p1++")∧"++show p2
             ConjP p1 p2 -> "("++show p1++")∧("++show p2++")"
             -- Disjunction
             DisyP p1@(St _) p2@(St _) -> show p1++"∨"++show p2
             DisyP p1@(St _) p2 -> show p1++"∨("++show p2++")"
             DisyP p1 p2@(St _) -> "("++show p1++")∨"++show p2
             DisyP p1 p2 -> "("++show p1++")∨("++show p2++")"
             -- neXt state
             X q -> case q of
                     St s@(Var _) -> "X"++show s
                     St s@(Neg _) -> "X"++show s
                     St s@(_)     -> "X"++show q
                     X q1 -> "X"++show q
                     _ -> "X("++show q++")"
             -- Until
             U (St (Neg "")) p2@(St _) -> "F"++show p2
             U (St (Neg "")) p2 -> "F("++show p2++")"
             U p1@(St _) p2@(St _) -> show p1++"U"++show p2
             U p1@(St _) p2 -> show p1++"U("++show p2++")"
             U p1 p2@(St _) -> "("++show p1++")U"++show p2
             U p1 p2 -> "("++show p1++")U("++show p2++")"
             -- Release
             R (St (Var "")) p2@(St _) -> "G"++show p2
             R (St (Var "")) p2 -> "G("++show p2++")"
             R p1@(St _) p2@(St _) -> show p1++"R"++show p2
             R p1@(St _) p2 -> show p1++"R("++show p2++")"
             R p1 p2@(St _) -> "("++show p1++")R"++show p2
             R p1 p2 -> "("++show p1++")R("++show p2++")"

