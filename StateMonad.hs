module StateMonad where

newtype StateM s a = ST (s -> (a, s))

runStateM::StateM s a->s->(a, s)
runStateM (ST st) s = st s

evalStateM::StateM s a->s->a
evalStateM (ST st) s = fst $ st s

instance Functor (StateM s) where
   fmap f st_a = ST $ \s -> let (a, s') = runStateM st_a s in
                            (f a, s')

instance Applicative (StateM s) where
   pure x        = ST (\s -> (x,s))
   st_f <*> st_a = ST $ \s -> let (f, s')  = runStateM st_f s
                                  (a, s'') = runStateM st_a s' in
                              (f a, s'')

instance Monad (StateM s) where
   return   = pure
   st >>= f = ST $ \s -> let (a, s') = runStateM st s in
                         runStateM (f a) s'

