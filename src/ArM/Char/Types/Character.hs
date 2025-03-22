{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Char.Types.Character
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Description :  Types to represent Characters and functions for advancement.
--
-- This module contains types to process characters, including 
-- persistence in JSON and advancement.
--
-----------------------------------------------------------------------------
module ArM.Char.Types.Character where

import GHC.Generics
import Data.Aeson
import Data.Maybe

import ArM.Char.Trait
import ArM.Char.Types.Advancement
import ArM.Char.Types.KeyPair
-- import ArM.Debug.Trace
import ArM.Helper

-- |
-- = Character

-- | The Character object includes both state information and
-- timeless concept information, as well as the advancements
-- defining the evolution through states.
data Character = Character 
    { charID :: String              -- ^ character ID, used to cross-reference
    , concept :: CharacterConcept   -- ^ concept is the timeless features of the character
    , state :: Maybe CharacterState -- ^ current state of the character
    , entryTime :: SeasonTime       -- ^ First season the character is in play
    , pregameDesign :: [ AugmentedAdvancement ]    -- ^ chargen already processed
    , pregameAdvancement :: [ Advancement ]        -- ^ chargen left to process
    , pastAdvancement :: [ AugmentedAdvancement ]  -- ^ past advancement (in game), most recent first
    , futureAdvancement :: [ Advancement ]         -- ^ future advancement (in game), next one firstk
    }  deriving (Eq,Generic)


-- | Default (empty) character object.
defaultCharacter :: Character 
defaultCharacter = Character { charID = "N/A"
                             , concept = defaultConcept
                             , state = Nothing
                             , entryTime = NoTime
                             , pregameDesign = [ ]
                             , pregameAdvancement = [ ]
                             , pastAdvancement = [ ]
                             , futureAdvancement = [ ]
       }  

instance Show Character where
   show = show . concept 


instance ToJSON Character where
    -- For efficiency - Not required
    toEncoding = genericToEncoding defaultOptions

instance FromJSON Character where
    parseJSON = withObject "Character" $ \v -> Character
        <$> v .: "charID"
        <*> v .: "concept"
        <*> v .:? "state" 
        <*> fmap ( fromMaybe NoTime) (v .:? "entryTime" )
        <*> fmap maybeList ( v .:? "pregameDesign" )
        <*> fmap maybeList ( v .:? "pregameAdvancement" )
        <*> fmap maybeList ( v .:? "pastAdvancement" )
        <*> fmap maybeList ( v .:? "futureAdvancement" )


-- | 
-- == Name and identity

-- | ID of a character.
-- This is currently implemented as the name.
-- The ID is used to refer to the character from other characters and
-- covenants, independently of the current state.
data CharacterID = CharacterID String
    deriving ( Show, Ord, Eq, Generic )

instance ToJSON CharacterID
instance FromJSON CharacterID

-- | get the ID of a character.
characterID :: Character -> CharacterID
characterID = CharacterID . charID

-- | Return the name of the character as a string, including house affiliation
-- if defined.
fullName :: Character -> String
fullName = fullConceptName . concept

-- | Return the name of the character as a string, including house affiliation
-- if defined.
fullConceptName :: CharacterConcept -> String
fullConceptName c = name c ++ (f $ house c)
      where f Nothing = ""
            f (Just x) | take 2 x == "ex" = " " ++ x
                       | otherwise  = " ex " ++ x

characterSeason :: Character -> SeasonTime
characterSeason c | isNothing st = NoTime
                  | otherwise = charTime $ fromJust st
           where st = state c

-- |
-- = CharacterConcept


-- | The CharacterType distinguishes between Magus, Companion, and Grog.
-- One may want to extend it for magic and faerie charaacters as well as
-- NPCs.
data CharacterType = Magus | Companion | Grog
       deriving (Eq,Generic,Show)
instance ToJSON CharacterType
instance FromJSON CharacterType

class CharacterLike ct where
     characterType :: ct -> CharacterType
     -- | Is the character a grog or not?
     isGrog :: ct -> Bool
     isGrog c | characterType c == Grog = True
              | otherwise = False
     -- | Is the character a magus or not?
     isMagus :: ct -> Bool
     isMagus c | characterType c == Magus = True
               | otherwise = False
instance CharacterLike Character where
     characterType = charType . concept


-- | The CharacterConcept is the timeless information about the character.
data CharacterConcept = CharacterConcept 
         { name :: String
         , charType :: CharacterType
         , briefConcept :: Maybe String
         , quirk :: Maybe String
         , appearance :: Maybe String
         , born :: Maybe Int
         , player :: Maybe String
         , house :: Maybe String
         , charGlance :: KeyPairList
         , charData :: KeyPairList
       }  deriving (Eq,Generic)

-- | Default (empty) character concept object.
defaultConcept :: CharacterConcept 
defaultConcept = CharacterConcept { name = "John Doe"
                                  , charType = Magus
                                  , briefConcept = Nothing
                                  , quirk = Nothing
                                  , appearance = Nothing
                                  , born = Nothing
                                  , player = Nothing
                                  , house = Nothing
                                  , charGlance = KeyPairList []
                                  , charData = KeyPairList []
       }  

instance ToJSON CharacterConcept where
    -- For efficiency - Not required
    toEncoding = genericToEncoding defaultOptions

instance FromJSON CharacterConcept where
    parseJSON = withObject "CharacterConcept" $ \v -> CharacterConcept
        <$> v .: "name"
        <*> v .: "charType"
        <*> v .:? "concept"
        <*> v .:? "quirk"
        <*> v .:? "appearance"
        <*> v .:? "born"
        <*> v .:? "player"
        <*> v .:? "house"
        <*> v .: "charGlance"
        <*> v .: "charData"

instance Show CharacterConcept where
   show c = fullConceptName c ++ "\n"
         ++ ( show $ charGlance c ) ++ ( show $ charData c )



-- |
-- = CharacterState

-- | The Character state is the stats of the character at a particular
-- point in time.
data CharacterState = CharacterState 
         { charTime :: SeasonTime
         , charSType :: CharacterType
         , traits :: [ Trait ]
         }  deriving (Eq,Generic,Show)


-- | Default (empty) character state object.
defaultCS :: CharacterState 
defaultCS = CharacterState 
         { charTime = NoTime
         , charSType = Magus
         , traits = [ ]
         }  

instance ToJSON CharacterState where
    -- For efficiency - Not required
    toEncoding = genericToEncoding defaultOptions
instance FromJSON CharacterState where
    parseJSON = withObject "CharacterState" $ \v -> CharacterState
        -- <$> v .:? "charTime"
        <$> fmap parseSeasonTime ( v .:? "charTime" )
        <*> v .: "charType" 
        <*> fmap maybeList ( v .:? "traits" )

