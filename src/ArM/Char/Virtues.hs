-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Char.Validation
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Description :  Validation of advancement (XP allocation etc.)
--
-----------------------------------------------------------------------------

module ArM.Char.Virtues (inferTraits
                        , laterLifeSQ
                        , getCharAllowance
                        ) where

import ArM.Char.Internal.Advancement
import ArM.Char.Trait
import ArM.Helper

import qualified Data.Map as Map
import Data.Maybe (isJust,fromJust)

import ArM.Debug.Trace

-- |
-- = Infer traits
--
-- The following functions are used to infer additional traits from virtues
-- and flaws.  This includes both affinities and puissant, which add traits
-- giving bonuses to regular abilities, and virtues which grant supernatural
-- abilities.

vl2 :: [ ( TraitKey, VF -> ProtoTrait ) ]
vl2 = [ ( VFKey "Puissant (art)",
         \ x -> defaultPT { art = Just $ vfDetail x, bonusScore = 
                trace "puissant ability" $ Just 3 } )
     , ( VFKey "Puissant (ability)",
              \ x -> defaultPT { ability = Just $ vfDetail x, bonusScore = 
                 trace "puissant ability" $ Just 2 } )
     , ( VFKey "Affinity with (art)",
              \ x -> defaultPT { art = Just $ vfDetail x, multiplyXP = Just 1.5 } )
     , ( VFKey "Affinity with (ability)",
              \ x -> defaultPT { ability = Just $ vfDetail x, multiplyXP = Just 1.5 } )
     ]


vl1 :: [ ( TraitKey, VF -> ProtoTrait ) ]
vl1 = [ (VFKey ab, \ _ -> defaultPT { ability = Just $ ab, xp = Just 5 } ) | ab <- snab ]

snab :: [ String ]
snab = [ "Second Sight", "Enchanting Music", "Dowsing",
         "Magic Sensitivity", "Animal Ken", "Wilderness Sense",
         "Sense Holiness and Unholiness",
         "Entrancement", "Premonitions",
         "Shapeshifter" ]

type VFMap = Map.Map TraitKey ( VF -> ProtoTrait ) 
virtueMap :: VFMap
virtueMap = Map.fromList $ vl1 ++ vl2

-- | Add ProtoTrait objects infered by current virtues and flaws
inferTraits :: [VF] -> [ProtoTrait]
inferTraits vfs = sortTraits rs
    where vf = [ Map.lookup (traitKey x) virtueMap | x <- vfs ]
          app Nothing _ = Nothing
          app (Just f) x = Just $ f x
          rs = filterNothing [ app g x | (g,x) <- zip vf vfs ]

-- |
-- = Infer Limits for Pregame Design

-- ( VFKey "Skilled Parens", id )  -- +60 xp +60 spells

llLookup:: String -> (Int,Int)
llLookup "Warrior" = (50,0) 
llLookup "Wealthy" = (0,20) 
llLookup "Poor" = (0,10) 
llLookup _  = (0,0) 
laterLifeXP :: [ VF ] -> (Int,Int)
laterLifeXP vfs = laterLifeXP' vfs (0,15)
laterLifeXP' :: [ VF ] -> (Int,Int) -> (Int,Int)
laterLifeXP' [] (x,y) = (x,y)
laterLifeXP' (vf:vfs) (x,y) = laterLifeXP' vfs $ (x'+x,f y y') 
         where (x',y') = llLookup $ vfname vf
               f 0 z = z
               f z _ = z

laterLifeSQ' :: Advancement -> (Int,Int) -> Int
laterLifeSQ' ad (x,y) = t
   where t | isJust (sourceQuality ad) = fromJust (sourceQuality ad)
           | isJust (advYears ad) = x+y*fromJust (advYears ad)
           | otherwise = x
laterLifeSQ :: [VF] -> Advancement -> Int
laterLifeSQ vfs ad = laterLifeSQ' ad $ laterLifeXP vfs
           
    
chLookup:: String -> Int
chLookup "Improved Characteristics" = 3
chLookup "Weak Characteristics" = 3
chLookup _  = 0

getCharAllowance :: [ VF ] -> Int
getCharAllowance = (+7) . sum . map ( chLookup . vfname )

-- |
-- = Infer Limits for Ingame Advancement 

{-
type AdvancementTransform = AugmentedAdvancement -> AugmentedAdvancement 
ad2 :: [ ( TraitKey, AdvancementTransform ) ]
ad2 = [ ( VFKey "Book learner", id )     -- SQ +3
      , ( VFKey "Independent Study", id ) -- SQ +2/+3
      , ( VFKey "Study Bonus", id )       -- reminder +2
      ]
-}
