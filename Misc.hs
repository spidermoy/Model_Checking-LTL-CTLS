module Misc where

data WordConstant = WordConstant { wcSigned :: Maybe Bool
                                 , wcBits :: Maybe Integer
                                 , wcValue :: Integer
                                 }
                    deriving Show
