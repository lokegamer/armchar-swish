-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Rules.Persistence
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Reasoner rules to extract triples for persistence.
--
-----------------------------------------------------------------------------

module ArM.Rules.Persistence where

import           ArM.Rules.Aux
import           ArM.Rules.RDFS
import qualified Swish.RDF.Graph as G
import qualified Swish.RDF.Query as Q
import           Swish.RDF.Vocabulary.RDF

import ArM.Resources

-- persistGraph' s g = persistGraph' $ G.merge s g
-- persistGraph' s g = foldGraphs $ Q.rdfQuerySubs vb tg
--     where vb = Q.rdfQueryFind qg g
--           qg = listToRDFGraph  [ G.arc sVar pVar cVar,
--                        G.arc pVar typeRes armPersistentProperty ]
--           tg = listToRDFGraph  [ G.arc sVar pVar cVar ]

persistRule = makeCRule "persistRule" 
    [ G.arc sVar pVar cVar,
      G.arc pVar typeRes armPersistentProperty ]
    [ G.arc sVar pVar cVar ]
persistTraitRule = makeCRule "persistTraitRule" 
    [ G.arc sVar (armRes "advanceTrait") tVar
    , G.arc tVar pVar oVar
    , G.arc pVar typeRes armPersistentProperty 
    ]
    [ G.arc sVar (armRes "advanceTrait") tVar
    , G.arc tVar pVar oVar
    ]
persistedRule id = makeCRule "persistedRule" 
    [ G.arc id pVar cVar,
      G.arc pVar typeRes armPersistentProperty ]
    [ G.arc id pVar cVar ]
persistedTraitRule id = makeCRule "persistedTraitRule" 
    [ G.arc id (armRes "advanceTrait") tVar
    , G.arc tVar pVar oVar
    , G.arc pVar typeRes armPersistentProperty 
    ]
    [ G.arc id (armRes "advanceTrait") tVar
    , G.arc tVar pVar oVar
    ]
persistedGraph g s = fwdApplyRules [ persistedRule s, persistedTraitRule s ] g
persistGraph s g = fwdApplyRules [ persistRule, persistTraitRule ] 
                 $ applyRDFS
                 $ G.merge s g
