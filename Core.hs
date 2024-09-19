module Core where

import Data.Set(Set, singleton, delete, insert, map, empty, elemAt, toList, member)
import Control.Monad(when, forM_)
import Control.Exception(catch, ErrorCall(ErrorCall))
import StateMonad(StateM(..), evalStateM)


type At = String

{- State formulas -}
data StateF = Var At
            | Neg At
            | ConjS StateF StateF
            | DisyS StateF StateF
            | A PathF
            | E PathF deriving (Eq, Ord)

{- Path formulas -}
data PathF = St StateF
           | DisyP PathF PathF
           | ConjP PathF PathF
           | U PathF PathF
           | V PathF PathF
           | X PathF deriving (Eq, Ord)


{- Negation Normal Form -}
negS::StateF->StateF
negS φ = case φ of
  Var a       -> Neg a
  Neg a       -> Var a
  ConjS φ₁ φ₂ -> DisyS (negS φ₁) (negS φ₂)
  DisyS φ₁ φ₂ -> ConjS (negS φ₁) (negS φ₂)
  A ф         -> E $ negP ф
  E ф         -> A $ negP ф

negP::PathF->PathF
negP ф = case ф of
  St φ        -> St $ negS φ
  ConjP ф₁ ф₂ -> DisyP (negP ф₁) (negP ф₂)
  DisyP ф₁ ф₂ -> ConjP (negP ф₁) (negP ф₂)
  X ф₁        -> X $ negP ф₁
  U ф₁ ф₂     -> V (negP ф₁) (negP ф₂)
  V ф₁ ф₂     -> U (negP ф₁) (negP ф₂)


{- Bot and Top -}
bot::StateF
bot = Var ""

top::StateF
top = Neg ""


{- Gф and Fф operators -}
opG::PathF->PathF
opG ф = case ф of
  -- GGф ≡ Gф
  V (St (Var "")) ф₁ -> opG ф₁
  -- GFGф ≡ FGф
  U (St (Neg "")) (V (St (Var "")) ф₁) -> opF $ opG ф₁
  _ -> V (St bot) ф

opF::PathF->PathF
opF ф = case ф of
  -- FFф ≡ Fф
  U (St (Neg "")) ф₁ -> opF ф₁
  -- FGFф ≡ GFф
  V (St (Var "")) (U (St (Neg "")) ф₁) -> opG $ opF ф₁
  _ -> U (St top) ф


{- Implication -}
impS::StateF->StateF->StateF
impS φ₁ φ₂ = if   φ₁ == φ₂
             then top
             else DisyS (negS φ₁) φ₂

impP::PathF->PathF->PathF
impP ф₁ ф₂ = if   ф₁ == ф₂
             then St top
             else DisyP (negP ф₁) ф₂


{- States are integers. -}
type State = Int

{- A Kripke Structure is a triple (n, r, l). 'n' indicates the states range [0 .. n].
   'r' is the transition function and 'l' maps states to variable sets. -}
newtype KripkeS = KS (Int, State->[State], State->(At->Bool))


{- Essentially, an assertion is a pair (s, Φ) and means:
   at least one formula ф ∊ Φ holds on 's' -}
newtype Assertion = Assrt (State, Set PathF) deriving (Eq, Ord)


{- Some operations on assertions -}
deleteF::PathF->Assertion->Assertion
deleteF ф (Assrt (s,_Φ)) = Assrt (s, delete ф _Φ)

insertF::PathF->Assertion->Assertion
insertF ф (Assrt (s, _Φ)) = Assrt (s, insert ф _Φ)


{- Subgoals are the core for the LTL model checker -}
data Subgoals = T | Subg [Assertion]

{- This function follows the formal semantic for LTL -}
subgoals::KripkeS->Assertion->Subgoals
subgoals ks@(KS (_, r, _)) σ@(Assrt (s, _Φ)) =
  if   _Φ == empty
  then Subg []
  else let  ф = elemAt 0 _Φ in
       case ф of
         St φ        -> if   evalMcCTLS ks (s, φ)
                        then T
                        else Subg [deleteF ф σ]
         DisyP ф₁ ф₂ -> Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ]
         ConjP ф₁ ф₂ -> if   ф₁ == ф₂ -- ф⋀ф ≡ ф
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        else Subg [insertF ф₁ $ deleteF ф σ,
                                   insertF ф₂ $ deleteF ф σ]
         U ф₁ ф₂     -> if   ф₁ == ф₂ -- фUф ≡ ф
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        -- ф₁Uф₂ ≡ (ф₁⋁ф₂)⋀(ф₂⋁(X(ф₁Uф₂)))
                        else Subg [insertF ф₁ $ insertF ф₂ $ deleteF ф σ,
                                   insertF ф₂ $ insertF (X ф) $ deleteF ф σ]
         V ф₁ ф₂     -> if   ф₁ == ф₂ -- фVф ≡ ф
                        then Subg [insertF ф₁ $ deleteF ф σ]
                        -- ф₁Vф₂ ≡ ф₂⋀(ф₁⋁(X(ф₁Vф₂)))
                        else Subg $ if   ф₁ == St bot
                                    then [insertF ф₂ $ deleteF ф σ, insertF (X ф) $ deleteF ф σ]
                                    else [insertF ф₂ $ deleteF ф σ, insertF ф₁ $ insertF (X ф) $ deleteF ф σ]
         X _         -> -- (Xф₁)⋁(Xф₂)⋁ ⋯ ⋁(Xф_n) ≡ X(ф₁⋁ф₂⋁ ⋯ ⋁ф_n)
                        let _Φ' = Data.Set.map (\(X ф') -> ф') _Φ in
                        Subg [Assrt (s', _Φ') | s' <- r s]


{- A list of assertions (that represents a cycle) is successful whether is generated by a V-formula. -}
checkSuccess::[Assertion]->Bool
checkSuccess v = let фs = concat [toList _Φ | Assrt (_, _Φ) <- v] in
                 (not . null) [V ф₁ ф₂ | V ф₁ ф₂ <- фs, ф₂ `notElem` фs]


{- LTL, LTL WITH COUNTEREXAMPLES AND CTL☆ MODEL CHECKING -}


{- A set of visited assertions to avoid to do repetitive work -}
type Vp = Set Assertion


{- Operations on Vp with state monad -}
elemVp::Assertion->StateM Vp Bool
elemVp σ = ST $ \v -> (member σ v, v)

insertVp::Assertion->StateM Vp ()
insertVp σ = ST $ \v -> ((), insert σ v)



mcALTL::KripkeS->Assertion->StateM Vp Bool
mcALTL ks' σ' = dfs ks' σ' []
  where
    dfs::KripkeS->Assertion->[Assertion]->StateM Vp Bool
    dfs ks σ stack = do
      σ_in_Vp <- elemVp σ
      if σ_in_Vp
      then return True
      else
        if σ `elem` stack
        then do
          let stack' = σ : takeWhile (σ /=) stack
              b      = checkSuccess stack'
          when b (forM_ stack' insertVp)
          return b
        else case subgoals ks σ of
          T -> do
            insertVp σ
            return True
          Subg σs -> case σs of
            [] -> return False
            _  -> do
              bs <- sequence [dfs ks σ'' (σ:stack) | σ'' <- σs]
              return (and bs)


updR::KripkeS->State->[State]->KripkeS
updR (KS (n, r, l)) s ss = KS (n, \s' -> if s'==s then ss else r s', l)

evalMcALTL::KripkeS->Assertion->Bool
evalMcALTL ks σ = evalStateM (mcALTL ks σ) empty

mcALTLSet::KripkeS->[State]->PathF->Bool
mcALTLSet ks ss ф = let ks' = updR ks (-1) ss in
                    evalMcALTL ks' (Assrt (-1, singleton $ X ф))


mcALTLc::KripkeS->Assertion->StateM Vp Bool
mcALTLc ks' σ_ = dfs ks' σ_ []
  where
    dfs::KripkeS->Assertion->[Assertion]->StateM Vp Bool
    dfs ks σ stack = do
      σ_in_Vp <- elemVp σ
      if σ_in_Vp
      then return True
      else
        if σ `elem` stack
        then do
          let stack' = σ : takeWhile (σ /=) stack
          if   checkSuccess stack'
          then forM_ stack' insertVp >> return True
          else cycleC (σ:stack)
        else case subgoals ks σ of
          T -> do
            insertVp σ
            return True
          Subg σs -> case σs of
            [] -> finiteC stack
            _  -> do
              bs <- sequence [dfs ks σ₁ (σ:stack) | σ₁ <- σs]
              return (and bs)
    finiteC::[Assertion]->a
    finiteC as = case as of
      ((Assrt (s, _Φ)):stack) -> error $
        "\n\n\tFinite counterexample\n\n" ++
        "s" ++ show s ++ " ⊬ " ++ show (toList _Φ) ++ "\n" ++
        concat [show σ' ++ "\n" | σ' <- filter (\(Assrt (s', _)) -> s' >= 0) stack]
      _ -> error ""
    cycleC::[Assertion]->a
    cycleC as = case as of
      (σ':_) -> error $
        "\n\n\tU-Cycle detected\n\n" ++
        concat [if   σ' == σ''
                then "--> " ++ show σ'' ++ "\n"
                else "    " ++ show σ'' ++ "\n" | σ'' <- filter (\(Assrt (s, _)) -> s >= 0) as]
      _ -> error ""


evalMcALTLc::KripkeS->Assertion->IO ()
evalMcALTLc ks σ = catch
  (print $ evalStateM (mcALTLc ks σ) empty)
  (\(ErrorCall counterexample) -> putStrLn counterexample)


mcALTLcSet::KripkeS->[State]->PathF->IO ()
mcALTLcSet ks ss ф = let ks' = updR ks (-1) ss in
                     evalMcALTLc ks' (Assrt (-1, singleton $ X ф))


type Vs = Set (State, StateF)

elemVs::(State,StateF)->StateM Vs Bool
elemVs p = ST $ \v -> (member p v, v)

insertVs::(State,StateF)->StateM Vs ()
insertVs p = ST $ \v -> ((), insert p v)


mcCTLS::KripkeS->(State, StateF)->StateM Vs Bool
mcCTLS ks@(KS (_, _, l)) (s, φ) = do
  s_φ_in_Vs <- elemVs (s, φ)
  if   s_φ_in_Vs
  then return True
  else case φ of
    Var a -> update (l s a)
    Neg a -> update ((not . l s) a)
    ConjS φ₁ φ₂ -> do
      b₁ <- mcCTLS ks (s, φ₁)
      b₂ <- mcCTLS ks (s, φ₂)
      update (b₁ && b₂)
    DisyS φ₁ φ₂ -> do
      b₁ <- mcCTLS ks (s, φ₁)
      b₂ <- mcCTLS ks (s, φ₂)
      update (b₁ || b₂)
    A ф -> update (evalMcALTL ks         (Assrt (s, singleton ф)))
    E ф -> update ((not . evalMcALTL ks) (Assrt (s, (singleton . negP) ф)))
  where
    update::Bool->StateM Vs Bool
    update b = when b (insertVs (s, φ)) >> return b


evalMcCTLS::KripkeS->(State, StateF)->Bool
evalMcCTLS ks (s, φ) = evalStateM (mcCTLS ks (s, φ)) empty

mcCTLSSet::(KripkeS,[State])->StateF->Bool
mcCTLSSet (ks,ss) φ = let ks' = updR ks (-1) ss in
                      evalMcCTLS ks' (-1, (A . X) $ St φ)


-- nuXmv local ubication
nuXmvPath::String
nuXmvPath = "/home/moy/nuXmv/bin/nuXmv"

smvOutput::String
smvOutput = "/home/moy/nuXmv/ejemplo_random.smv"
{-====================================================================================-}

{-
 ******************
 * DATA INSTANCES *
 ****************** -}

instance Show Assertion where
   show (Assrt (s, _Φ)) = "s" ++ show s ++ " ⊢ " ++ show (toList _Φ)


instance Show StateF where
  show sf = case sf of
    -- Variables
    Var "" -> "⊥"
    Var a  -> a
    Neg "" -> "┬"
    Neg a  -> "¬" ++ a
    -- Conjunction
    ConjS (Var p) (Var q) -> p ++ " ⋀ " ++ q
    ConjS (Neg p) (Neg q) -> "¬" ++ p ++ " ⋀ ¬" ++ q
    ConjS s1 (Var q) -> case s1 of
      Neg _ -> show s1 ++ " ⋀ " ++ q
      _     -> "(" ++ show s1 ++ ") ⋀ " ++ q
    ConjS (Var p) s2 -> case s2 of
      Neg q -> p ++ " ⋀ ¬" ++ q
      _ -> p ++ " ⋀ (" ++ show s2 ++ ")"
    ConjS s1@(Neg _) s2 -> show s1 ++ " ⋀ (" ++ show s2 ++ ")"
    ConjS s1 s2@(Neg _) -> "(" ++ show s1 ++ ") ⋀ " ++ show s2
    ConjS s1 s2         -> "(" ++ show s1 ++ ") ⋀ (" ++ show s2 ++ ")"
    -- Disjunction
    DisyS (Var p) (Var q) -> p ++ " ⋁ " ++ q
    DisyS (Neg p) (Neg q) -> "¬" ++ p ++ " ⋁ ¬" ++ q
    DisyS s1 (Var q) -> case s1 of
      Neg _ -> show s1 ++ " ⋁ " ++ q
      _     -> "(" ++ show s1 ++ ") ⋁ " ++ q
    DisyS (Var p) s2 -> case s2 of
      Neg q -> p ++ " ⋁ ¬" ++ q
      _     -> p ++ " ⋁ (" ++ show s2 ++ ")"
    DisyS s1@(Neg _) s2 -> show s1 ++ " ⋁ (" ++ show s2 ++ ")"
    DisyS s1 s2@(Neg _) -> "(" ++ show s1 ++ ") ⋁ " ++ show s2
    DisyS s1 s2         -> "(" ++ show s1 ++ ") ⋁ (" ++ show s2 ++ ")"
    -- For All
    A p -> case p of
      X p'               -> "AX " ++ show p'
      U (St (Neg "")) p' -> "AF " ++ show p'
      V (St (Var "")) p' -> "AG " ++ show p'
      _                  -> "A[" ++ show p ++ "]"
    -- Exists
    E p -> case p of
      X p'               -> "EX " ++ show p'
      U (St (Neg "")) p' -> "EF " ++ show p'
      V (St (Var "")) p' -> "EG " ++ show p'
      _                  -> "E[" ++ show p ++ "]"


instance Show PathF where
  show p = case p of
    -- State Formulas
    St s -> case s of
      Var _ -> show s
      Neg _ -> show s
      _     -> "(" ++ show s ++ ")"
    -- Conjunction
    ConjP p1@(St _) p2@(St _) -> show p1 ++ " ⋀ " ++ show p2
    ConjP p1@(St _) p2        -> show p1 ++ " ⋀ (" ++ show p2 ++ ")"
    ConjP p1 p2@(St _)        -> "(" ++ show p1 ++ ") ⋀ " ++ show p2
    ConjP p1 p2               -> "(" ++ show p1 ++ ") ⋀ (" ++ show p2 ++ ")"
    -- Disjunction
    DisyP p1@(St _) p2@(St _) -> show p1 ++ " ⋁ " ++ show p2
    DisyP p1@(St _) p2        -> show p1 ++ " ⋁ (" ++ show p2 ++ ")"
    DisyP p1 p2@(St _)        -> "(" ++ show p1 ++ ") ⋁ " ++ show p2
    DisyP p1 p2               -> "(" ++ show p1 ++ ") ⋁ (" ++ show p2 ++ ")"
    -- neXt state
    X q -> case q of
      St s@(Var _)      -> "X" ++ show s
      St s@(Neg _)      -> "X" ++ show s
      St _              -> "X" ++ show q
      X _               -> "X" ++ show q
      U (St (Neg "")) _ -> "X" ++ show q
      V (St (Var "")) _ -> "X" ++ show q
      _                 -> "X(" ++ show q ++ ")"
    -- Until
    U (St (Neg "")) p2@(St _) -> "F" ++ show p2
    U (St (Neg "")) p2        -> "F(" ++ show p2 ++ ")"
    U p1@(St _) p2@(St _)     -> show p1 ++ " U " ++ show p2
    U p1@(St _) p2            -> show p1 ++ " U (" ++ show p2 ++ ")"
    U p1 p2@(St _)            -> "(" ++ show p1 ++ ") U " ++ show p2
    U p1 p2                   -> "(" ++ show p1 ++ ") U (" ++ show p2 ++ ")"
    -- Release
    V (St (Var "")) p2@(St _) -> "G" ++ show p2
    V (St (Var "")) p2        -> "G(" ++ show p2 ++ ")"
    V p1@(St _) p2@(St _)     -> show p1 ++ " V " ++ show p2
    V p1@(St _) p2            -> show p1 ++ " V (" ++ show p2 ++")"
    V p1 p2@(St _)            -> "(" ++ show p1 ++ ") V " ++ show p2
    V p1 p2                   -> "(" ++ show p1 ++ ") V (" ++ show p2 ++ ")"
