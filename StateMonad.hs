{-# LANGUAGE TupleSections #-}

{- Very simple Monad State implementation. -}
module StateMonad where

-- With state 's' and values 'a'.
newtype StateM s a = ST (s -> (a, s))

-- Run with state 'st'.
runStateM::StateM s a->s->(a, s)
runStateM (ST st) = st

-- Eval with state 'st'.
evalStateM::StateM s a->s->a
evalStateM (ST st) = fst . st

instance Functor (StateM s) where
  fmap f st_a = ST $ \s -> let (a, s') = runStateM st_a s in (f a, s')

instance Applicative (StateM s) where
  pure x        = ST (x,)
  st_f <*> st_a = ST $ \s -> let (f, s')  = runStateM st_f s
                                 (a, s'') = runStateM st_a s' in
                             (f a, s'')

instance Monad (StateM s) where
  st >>= f = ST $ \s -> let (a, s') = runStateM st s in runStateM (f a) s'

