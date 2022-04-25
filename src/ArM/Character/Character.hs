{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Character.Character
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- The CharacterSheet data type and corresponding functions
--
-----------------------------------------------------------------------------
module ArM.Character.Character ( CharacterSheet(..)
                               , csToRDFGraph
                               , getGameStartCharacter
                               , getInitialCS
                               , getAllCS
                               ) where

import Data.Set (fromList)
import Swish.RDF.Parser.N3 (parseN3fromText)
import Swish.RDF.Graph as G
import Swish.RDF.Query as Q
import qualified Data.Text.Lazy as T
import Swish.RDF.VarBinding as VB 
import Network.URI (URI,parseURI)
import Swish.VarBinding  (vbMap)
import Data.Maybe
import Data.List (sort)
import ArM.Resources
import ArM.Character.Trait
import ArM.Character.Advancement
import ArM.KeyPair
import qualified ArM.Character.Metadata as CM
import ArM.BlankNode
import ArM.Rules.Aux

getCharacterMetadata = CM.getCharacterMetadata

data CharacterSheet = CharacterSheet {
         csID :: RDFLabel,
         sheetID :: Maybe RDFLabel,
         csYear :: Maybe Int,
         csSeason :: String,
         -- csSeason :: Maybe RDFLabel,
         csTraits :: [Trait],
         csMetadata :: [KeyValuePair]
       }  deriving (Eq)
instance Show CharacterSheet where
    show cs = "**" ++ show (csID cs) ++ "**\n" 
           ++ "-- " ++ ( showSheetID ) cs ++ "\n"
           ++ "Traits:\n" ++ showw ( csTraits cs )
           ++ "Metadata Triples:\n" ++ showw ( csMetadata cs )
        where showw [] = ""
              showw (x:xs) = "  " ++ show x ++ "\n" ++ showw xs
defaultCS = CharacterSheet {
         csID = noSuchCharacter,
         sheetID = Nothing,
         csYear = Nothing,
         csSeason = "",
         csTraits = [],
         csMetadata = []
       }  

showSheetID :: CharacterSheet -> String
showSheetID = f . sheetID
    where f Nothing = "no sheet ID"
          f (Just x) = show x

getGameStartCharacter :: RDFGraph -> RDFLabel -> Maybe CharacterSheet
getGameStartCharacter g label | x == Nothing = Nothing
                              | otherwise    = Just $ getGameStartCS g $ fromJust x
     where x = getInitialCS g label

getGameStartCS :: RDFGraph -> CharacterSheet -> CharacterSheet
getGameStartCS g cs = foldl advanceCharacter cs as
    where as = sort $ getPregameAdvancements g $ csID cs

-- | Given a graph and a string identifying a character
-- make a list of all ingame character sheets for the 
-- character by applying all available advancements.
getAllCS :: RDFGraph -> RDFLabel -> Maybe [CharacterSheet]
getAllCS g c | cs == Nothing = Nothing
             | otherwise     = Just $ cs':advanceList cs' as
    where cs = getGameStartCharacter g c
          cs' = fromJust cs
          as = sort $ getIngameAdvancements g c

-- | Given a character sheet and a sorted list of advancements,
-- apply all the advancements in order and produce a list
-- of character sheets for every step
advanceList :: CharacterSheet -> [Advancement] -> [CharacterSheet]
advanceList _ [] = []
advanceList cs (x:xs) = advanceCharacter cs x : advanceList cs xs

-- | apply a given Advancement to a given CharacterSheet
advanceCharacter :: CharacterSheet -> Advancement -> CharacterSheet 
advanceCharacter cs adv = cs { 
     sheetID = Nothing,
     csYear = year adv,
     csSeason = season adv,
     csTraits = advanceTraitList (csTraits cs) (traits adv)
     }


-- | get initial CharacterSheet from an RDFGraph
getInitialCS :: RDFGraph -> RDFLabel -> Maybe CharacterSheet
getInitialCS g label | x == Nothing = Nothing 
                     | otherwise    = Just $ fixCS g $ fromJust x
                           where x = getInitialCS' g label

getInitialCS' :: RDFGraph -> RDFLabel -> Maybe CharacterSheet
getInitialCS' g c | x == Nothing = Nothing
                  | otherwise = Just defaultCS {
            csID = c,
            sheetID = x,
            csTraits = [],
            csMetadata = getCharacterMetadata g cs
         }
         where cs = show $ fromJust $ x
               x = getInitialSheet g c

-- | Given an identifier for the character, find the identifier for
-- the initial character sheet
getInitialSheet :: RDFGraph -> RDFLabel -> Maybe RDFLabel
getInitialSheet g c = vbMap vb (G.Var "s")
    where 
      vb = head $ rdfQueryFind q g
      q = toRDFGraph $ fromList $ [ arc c (Res $ makeSN "hasInitialSheet") sVar ]


-- | Auxiliary for 'getInitialSheet'
fixCS :: RDFGraph -> CharacterSheet -> CharacterSheet
fixCS g a = a { csTraits = sort $ getTraits a g }

-- | Get a list of traits. Auxiliary function for 'fixCS'.
getTraits :: CharacterSheet -> RDFGraph -> [Trait]
getTraits a g | x == Nothing = []
              | otherwise    = map toTrait 
               $ keypairSplit $ map objectFromBinding $ rdfQueryFind q g 
    where q = cqt $ show $ fromJust $ x
          x = sheetID a

-- | Query Graph to get traits for CharacterSheet
cqt :: String -> RDFGraph
cqt s = qparse $ prefixes 
      ++ s ++ " <https://hg.schaathun.net/armchar/schema#hasTrait> ?id . " 
      ++ "?id ?property ?value . "
      ++ "?property rdfs:label ?label . "

csToRDFGraph :: CharacterSheet -> RDFGraph
csToRDFGraph cs =
         ( toRDFGraph .  fromList . fst . runBlank ( csToArcListM cs ) )
         ("charsheet",1)

csToArcListM :: CharacterSheet -> BlankState [RDFTriple]
csToArcListM cs = do
          x <- getSheetIDM cs $ sheetID cs
          ts <- mapM (traitToArcListM x) (csTraits cs)
          let ms = keyvalueToArcList x (csMetadata cs)
          let ct = arc x isCharacterLabel charlabel
          let ct1 = arc x typeRes csRes 
          return $ ct1:ct:foldl (++) ms ts
    where 
          charlabel = csID cs

getSheetIDM :: CharacterSheet -> Maybe RDFLabel -> BlankState RDFLabel
getSheetIDM _ Nothing = getBlank
getSheetIDM _ (Just x) = return x
