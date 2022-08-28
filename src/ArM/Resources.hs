{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Resources
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- This module defines namespaces, URIs, and filenames used in the project.
-- It also defines utility functions to create RDFLabel-s from strings.
--
-- Much of this data should be made configurable.
--
-----------------------------------------------------------------------------
module ArM.Resources where

import Swish.Namespace
import Swish.RDF.Graph
import Network.URI
import qualified Data.Text as T
import qualified Swish.QName as QN
import           Data.Text (unpack)

-- * Ontology Files

baseURI :: Maybe URI
baseURI = Nothing
    
-- * URIs and NameSpaces

auth = URIAuth "" "hg.schaathun.net" ""
armURI :: URI 
armURI = URI { uriScheme = "https:",
           uriAuthority = Just auth,
           uriPath = "/armchar/schema",
           uriQuery = "",
           uriFragment = "#" }
armrURI :: URI 
armrURI = URI { uriScheme = "https:",
           uriAuthority = Just auth,
           uriPath = "/armchar/resources",
           uriQuery = "",
           uriFragment = "#" }
rulesURI :: URI 
rulesURI = URI { uriScheme = "https:",
           uriAuthority = Just auth,
           uriPath = "/armchar/rules",
           uriQuery = "",
           uriFragment = "#" }
armcharURI :: URI 
armcharURI = URI { uriScheme = "https:",
           uriAuthority = Just auth,
           uriPath = "/armchar/character/",
           uriQuery = "",
           uriFragment = "" }
armNS = makeNamespace (Just $ T.pack "arm") armURI
rulesNS = makeNamespace (Just $ T.pack "armrules") armURI

-- * Utility functions to manage local names

-- | Define a local name from a String
newLName s = case (QN.newLName $ T.pack s) of
   (Nothing) -> QN.emptyLName
   (Just ln) -> ln

-- | Extract the local name (as String) from an RDFLabel.
getLocalID :: RDFLabel -> Maybe String
getLocalID lab = f $ fromRDFLabel lab 
      where f Nothing = Nothing
            f (Just x) = Just $ unpack $ QN.getLName $ getScopeLocal x

-- * Convenience functions to make ontology labels

makeSN s = makeScopedName (Just $ T.pack "arm") armURI (newLName s)
armRes :: String -> RDFLabel
armRes = Res . makeSN
armcharRes :: String -> RDFLabel
armcharRes s = Res $ makeScopedName (Just $ T.pack "armchar") armcharURI (newLName s)
armrRes :: String -> RDFLabel
armrRes s = Res $ makeScopedName (Just $ T.pack "armr") armrURI (newLName s)

-- * Ontology Labels

isCharacterLabel :: RDFLabel
isCharacterLabel = armRes  "isCharacter"
repeatableLabel :: RDFLabel
repeatableLabel = armRes  "RepeatableTrait"
xptraitLabel :: RDFLabel
xptraitLabel = armRes  "XPTrait"
accelleratedtraitLabel :: RDFLabel
accelleratedtraitLabel = armRes  "AccelleratedTrait"
addXPLabel :: RDFLabel
addXPLabel = armRes  "addedXP"
totalXPLabel :: RDFLabel
totalXPLabel = armRes "hasTotalXP" 
hasXPLabel :: RDFLabel
hasXPLabel = armRes "hasXP" 

-- | An RDFLabel used as a kind of Null pointer for traits and items.
noSuchTrait :: RDFLabel
noSuchTrait = armRes "noSuchTrait" 
-- | An RDFLabel used as a kind of Null pointer for advancements.
noSuchAdvancement :: RDFLabel
noSuchAdvancement = armRes "noSuchAdvancement" 
-- | An RDFLabel used as a kind of Null pointer for characters.
noSuchCharacter :: RDFLabel
noSuchCharacter = armRes "noSuchCharacter" 

atSeason :: RDFLabel
atSeason = armRes "atSeason" 
inYear :: RDFLabel
inYear = armRes "inYear" 

hasAdvancementIndex :: RDFLabel
hasAdvancementIndex = armRes "hasAdvancementIndex" 
hasAdvancementType :: RDFLabel
hasAdvancementType = armRes "hasAdvancementType" 
hasAdvancementTypeString = armRes "hasAdvancementTypeString" 
prefixedidRes = armRes "prefixedid" 
armViewProperty = armRes "ViewProperty" 
armPersistentProperty = armRes "PersistentProperty" 
armCharacterProperty = armRes "CharacterProperty" 
armCharacter = armRes "Character" 
