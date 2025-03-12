
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Char.Spell
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
-- 
-- Description :  Spell Records
--
--
-----------------------------------------------------------------------------
module ArM.Char.Spell ( SpellRecord(..)
                       , fromCSVline
                       ) where

import ArM.Char.Trait
import GHC.Generics
import Data.List.Split

data SpellRecord = SpellRecord
                   { spellKey :: TraitKey
                   , lvl :: Int
                   , technique :: String
                   , techniqueReq :: [String]
                   , form :: String
                   , formReq :: [String]
                   , specialSpell :: [String]
                   , description :: String
                   , design :: String 
                   }
           deriving (Ord, Eq, Generic)
defaultSR :: SpellRecord
defaultSR = SpellRecord
                   { spellKey = OtherTraitKey "None"
                   , lvl = 0
                   , technique = ""
                   , techniqueReq = []
                   , form = ""
                   , formReq = []
                   , specialSpell = []
                   , description = ""
                   , design = ""
                   }

fromCSVline :: [String] -> SpellRecord
fromCSVline (x1:x2:x3:x4:x5:x6:x7:x8:x9:x10:_) =
      defaultSR { spellKey = SpellKey x1 x2
                , lvl = read x3
                , technique = x4
                , techniqueReq = splitOn ";" x5
                , form = x6
                , formReq = splitOn ";" x7
                , specialSpell = splitOn ";" x8
                , description = x9
                , design = x10
                }
fromCSVline _ = defaultSR
