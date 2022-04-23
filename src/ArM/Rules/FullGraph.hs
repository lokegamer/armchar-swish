-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Rules.FullGraph
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Reasoning rules on the full graph using the resource ontology.
--
-----------------------------------------------------------------------------

module ArM.Rules.FullGraph where

import Swish.RDF.Ruleset
import qualified Data.Text as T
import Swish.Rule
import Swish.RDF.Graph
import Swish.RDF.Vocabulary.RDF
import Swish.RDF.Vocabulary.XSD
import ArM.Resources
import ArM.Rules.Aux
import Swish.VarBinding (varBindingId) 

-- | Infere resource properties from class
prepareGraph = fwdApplyListR [ advancevfgrantRule, grantRule, spectraitRule, rRule ]

rRule = makeCRule "rRule" l1 l2
    where l1 = [ arc sVar ( Res $ makeSN "traitClass" ) tVar,
               arc tVar pVar oVar,
               arc pVar typeRes ( Res $ makeSN "TraitProperty" )  ]
          l2 = [arc sVar pVar oVar]


stcRes = Res $ makeSN "SpecialTraitClass" 
stcArc = arc tVar typeRes stcRes
isSTRes = Res $ makeSN "isSpecialTrait" 
isSTArc = arc sVar isSTRes tVar

spectraitRule = makeCRule  "spectraitRule" [ tArc, stcArc ] [ isSTArc ]


-- | apply grantsTrait to a CharacterSheet
grantRule = makeCRule  "grantRule" 
     [ arc sVar htRes oVar,     -- s hasTrait o
       arc oVar typeRes tVar,   -- o a t
       arc sVar typeRes csRes,  -- s a CharacterSheet
       arc tVar gtRes cVar ]    -- o grantsTrait c
     [ arc sVar htRes cVar ]    -- s

-- | apply grantsTrait to an Advancement
advancevfgrantRule = makeCRule  "advancevfgrantRule" 
     [ arc sVar atRes oVar,
       arc oVar typeRes tVar,   -- o a t
       arc sVar typeRes caRes,
       arc tVar gtRes cVar ]
     [ arc sVar atRes oVar ]