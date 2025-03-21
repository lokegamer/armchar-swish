{-# LANGUAGE DeriveGeneric #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Cov.Saga
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Description :  Saga type with references to constituent files and objects.
--
--
-----------------------------------------------------------------------------
module ArM.Cov.Saga where

-- import Data.Maybe 
import Data.Aeson 
import GHC.Generics

-- import ArM.Char.Trait
import ArM.Char.Character
import ArM.Char.Types.Advancement
import ArM.Char.Spell
import ArM.Char.Markdown
import ArM.Cov.Covenant
import ArM.BasicIO
import ArM.Helper



-- import ArM.Debug.Trace
--

-- |
-- = Saga objects

-- | A Saga as it is processed in memory.
-- Multiple files have to be loaded to generate a Saga object from a `SagaFile`.
data Saga = Saga 
         { sagaTitle :: String
         , seasonTime :: SeasonTime
         , covenants :: [Covenant]
         , rootDir :: String
         , gameStartCharacters :: [Character]
         , currentCharacters :: [Character]
         , spells :: SpellDB
       }  deriving (Eq,Show)

sagaStateName :: Saga -> String
sagaStateName s = sagaTitle s ++ " - " ++ (show $ seasonTime s)

sagaStartName :: Saga -> String
sagaStartName s = sagaTitle s ++ " - Game Start"


gamestartDir :: Saga -> String
gamestartDir saga = rootDir saga ++ "/GameStart/"
currentDir :: Saga -> String
currentDir saga = rootDir saga ++ "/" ++ (show $ seasonTime saga) ++ "/"

sagaGameStartIndex :: Saga -> OList
sagaGameStartIndex saga = OList 
        [ OString $ "# " ++ sagaTitle saga ++ " - Game Start"
        , OString ""
        , characterIndex $ gameStartCharacters saga
        ]
sagaCurrentIndex :: Saga -> OList
sagaCurrentIndex saga = OList 
        [ OString $ "# " ++ sagaTitle saga ++ " - " ++ (show $ seasonTime saga)
        , OString ""
        , characterIndex $ currentCharacters saga
        ]

sagaIndex :: Saga -> OList
sagaIndex saga = OList 
        [ OString $ "# " ++ sagaTitle saga
        , OString ""
        , OString $ "+ " ++ wikiLink (sagaStateName saga) 
        , OString $ "+ " ++ wikiLink (sagaStateName saga ++ " Errors") 
        , OString $ "+ " ++ wikiLink (sagaStartName saga) 
        , OString $ "+ " ++ wikiLink (sagaStartName saga ++ " Errors") 
        ]

covenantLink :: Covenant -> String
covenantLink cov = wikiLink txt 
   where txt = covenantName cov ++ " " ++ covenantSeason cov

advanceSaga' :: SeasonTime -> Saga -> Saga
advanceSaga' t saga = saga { currentCharacters = map (advanceCharacter t) ( gameStartCharacters saga ) }

advanceSaga :: SagaFile -> Saga -> Saga
advanceSaga t saga = advanceSaga' (currentSeason t) saga

-- | A Saga as it is stored on file.
-- The main purpose here is to identify all the files used for characters and
-- other data in the saga.
data SagaFile = SagaFile 
         { title :: String
         , currentSeason :: SeasonTime
         , rootDirectory :: Maybe String
         , covenantFiles :: [String]
         , characterFiles :: [String]
         , spellFile :: String
       }  deriving (Eq,Generic,Show)

instance ToJSON SagaFile 
instance FromJSON SagaFile 

instance Markdown Saga where
    printMD saga = OList 
        [ OString $ "# " ++ sagaTitle saga
        ]

-- |
-- = Advancement


-- |
-- = Other Markdown Output

-- |
-- == Error reports


-- | Get errors from the ingam advancements of a given character.
pregameCharErrors :: Character -> [(String,[String])]
pregameCharErrors c = renderCharErrors c $ pregameDesign c

-- | Get errors from the ingam advancements of a given character.
ingameCharErrors :: Character -> [(String,[String])]
ingameCharErrors c = renderCharErrors c $ pastAdvancement c

-- | Format strins for `pregameCharErrors` and `ingameCharErrors`
renderCharErrors :: Character -> [AugmentedAdvancement] -> [(String,[String])]
renderCharErrors c as = ff $ map f as
   where f a = (charID c ++ ": " ++ augHead (season a) (mode a)
               , filterError $ validation a)
         ff ((_,[]):xs) = ff xs
         ff (x:xs) = x:ff xs
         ff [] = []

-- | Format a header for `rencerCharErrors`
augHead :: SeasonTime -> Maybe String -> String
augHead NoTime Nothing = ("??" )
augHead x Nothing = (show x )
augHead NoTime (Just x) = x
augHead x (Just z) = (show x  ++ " " ++ z)

-- | Get errors from a list of Validation objects
filterError :: [Validation] -> [String]
filterError (Validated _:xs) = filterError xs
filterError (ValidationError x:xs) = x:filterError xs
filterError [] = []

-- | Exctract a list of validation errors 
pregameErrors :: Saga -> [String]
pregameErrors saga = foldl (++) [] $ map formatOutput vvs
    where cs = gameStartCharacters saga
          vs = map pregameCharErrors  cs
          vvs = foldl (++) [] vs
          formatOutput (x,xs) = ("+ " ++ x):map ("    + "++) xs

-- | Exctract a list of validation errors 
ingameErrors :: Saga -> [String]
ingameErrors saga = foldl (++) [] $ map formatOutput vvs
    where cs = currentCharacters saga
          vs = map ingameCharErrors  cs
          vvs = foldl (++) [] vs
          formatOutput (x,xs) = ("+ " ++ x):map ("    + "++) xs

-- | Character Index
-- ==

-- | Return the canonical file name for the character, without directory.
-- This is currently the full name with a ".md" suffix.
charFileName :: Character -> String
charFileName = (++".md") . fullName 

-- | Write a single item for `characterIndex`
characterIndexLine :: Character -> OList
characterIndexLine c = OString $ "+ " ++ wikiLink (characterStateName c) 

-- | Write a bullet list of links for a list of characters
characterIndex :: [Character] -> OList
characterIndex = OList . map characterIndexLine 

