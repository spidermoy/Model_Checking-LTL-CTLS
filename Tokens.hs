module Tokens where

import Misc

data Token
     = Identifier String
     | Key Keyword
     | Number Integer
     | WordConst WordConstant
     | Sym Symbol
     deriving Show

data Keyword
     = KeyMODULE     | KeyDEFINE     | KeyMDEFINE
     | KeyCONSTANTS  | KeyVAR        | KeyIVAR
     | KeyFROZENVAR  | KeyINIT       | KeyTRANS
     | KeyINVAR      | KeyCTLSPEC
     | KeyLTLSPEC    | KeyPSLSPEC    | KeyCOMPUTE
     | KeyNAME       | KeyINVARSPEC  | KeyFAIRNESS
     | KeyJUSTICE    | KeyCOMPASSION | KeyISA
     | KeyASSIGN     | KeyCONSTRAINT | KeySIMPWFF
     | KeyCTLWFF     | KeyLTLWFF     | KeyPSLWFF
     | KeyCOMPWFF    | KeyIN         | KeyMIN
     | KeyMAX        | KeyMIRROR     | KeyPRED
     | KeyPREDICATES | Keyprocess    | Keyarray
     | Keyof         | Keyboolean    | Keyinteger
     | Keyreal       | Keyword       | Keyword1
     | Keybool       | Keysigned     | Keyunsigned
     | Keyextend     | Keyresize     | Keysizeof
     | Keyuwconst    | Keyswconst    | KeyEX
     | KeyAX         | KeyEF         | KeyAF
     | KeyEG         | KeyAG         | KeyE
     | KeyF          | KeyO          | KeyG
     | KeyH          | KeyX          | KeyY
     | KeyZ          | KeyA          | KeyU 
     | KeyS          | KeyV          | KeyT
     | KeyBU         | KeyEBF        | KeyABF
     | KeyEBG        | KeyABG        | Keycase
     | Keyesac       | Keymod        | Keynext
     | Keyinit       | Keyunion      | Keyin
     | Keyxor        | Keyxnor       | Keyself
     | KeyTRUE       | KeyFALSE      | Keycount
     | Keytoint
     deriving Show

data Symbol
     = Bracket { bracketType :: BracketType
               , bracketClosing :: Bool
               }
     | LNot | LAnd | LOr | LImpl | LEquiv | LEq | LNEq
     | Tern
     | WConcat
     | LT | GT | LTE | GTE
     | Minus | Plus | Mult | Div
     | ShiftL | ShiftR
     | Ask
     | Comma | Colon | Semicolon | DotDot | Dot
     | Assign
     deriving Show

data BracketType = Parentheses
                 | Square
                 | Curly
                 deriving Show
