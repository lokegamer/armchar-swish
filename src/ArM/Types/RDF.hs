-----------------------------------------------------------------------------
-- |
-- Module      :  ArM.Types.RDF
-- Copyright   :  (c) Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-- Types to parse RDFLabel objects.
--
-----------------------------------------------------------------------------

module ArM.Types.RDF ( FromRDFGraph(..)
                     , ToRDFGraph(..) 
                     , stringToRDFLabel
                     ) where

import Swish.RDF.Graph
import Data.Aeson
import Data.Aeson.Key
import qualified Data.Text as T
import ArM.Swish.Resources
import Data.List       (intercalate)
import Swish.Namespace (ScopedName)
import Data.List.Split (splitOn)
import Data.Maybe (fromJust)
import Network.URI (parseURI)
import Swish.RDF.Vocabulary.XSD (xsdInteger)
import Control.Monad (mzero)

import ArM.Debug.NoTrace

-- | A `KVP` holds a prefixed ID for RDF serialisation.
-- In JSON this appears as an object with only the `prefixedid` attribute.
data KVP = KVP { prefixedid :: String }
   deriving (Show,Eq)
instance ToJSON KVP where 
    toJSON k = object [ fromString "prefixedid" .= toJSON ( prefixedid k ) ]
instance FromJSON KVP where 
    parseJSON (Object x) = KVP <$> x .: fromString "prefixedid"
    parseJSON _ = mzero


-- |
-- = RDF Conversion Classes

class FromRDFGraph a where
    fromRDFGraph :: RDFGraph -> RDFLabel -> a 
    rawFromRDFGraph :: RDFGraph -> RDFLabel -> a 
    rawFromRDFGraph = fromRDFGraph
    viewFromRDFGraph :: RDFGraph -> RDFLabel -> a 
    viewFromRDFGraph = fromRDFGraph
class ToRDFGraph a where
    makeRDFGraph :: a -> RDFGraph

-- |
-- = RDFLabel

instance ToJSON RDFLabel where
    toJSON  = f . labelToData
        where f (Left x) = toJSON x
              f (Right (Left x)) = toJSON x
              f (Right (Right x)) = toJSON x
instance FromJSON RDFLabel where
   parseJSON (Number x) = return $ TypedLit (T.pack $ show  (truncate x::Int)) xsdInteger
   parseJSON (String x) = return $ Lit x
   parseJSON x = do
       s <- fmap prefixedid $ parseJSON $ trace "RDFLabel other" $ ttrace x
       case stringToRDFLabel s of
          Left r -> trace "return from FromJSON RDFLabel" $ return r
          Right r -> trace "Fail in FromJSON RDFLabel" $ fail r

-- | Convert an RDFLabel to String/Int/URI for serialisation purposes.
labelToData :: RDFLabel -> Either KVP (Either Int String)
labelToData l | i /= Nothing = Right $ Left (fromJust i)
              | s /= Nothing = Right $ Right (fromJust s)
              | uri /= Nothing = Left $ KVP (show $ fromJust uri)
              | otherwise    = Right (Right (show l))
    where  s = fromRDFLabel l :: Maybe String
           i = fromRDFLabel l :: Maybe Int
           uri = fromRDFLabel l :: Maybe ScopedName

-- | Convert a string to an RDFLabel, parsing URIs
stringToRDFLabel :: String -> Either RDFLabel String
stringToRDFLabel "" = Right "Cannont make a label from an empty string"
stringToRDFLabel (k:ks) 
        | k == '<'  = tl $ parseURI uri 
        | splits == [] = Right "Parser error: empty string."
        | splits' == [] = Right "Parser error: neither prefixed ID nor full URI."
        | px == Nothing = Right "Parse error: Prefix not recognised"
        | otherwise = Left $ fromJust px
     where splits = splitOn ":" $ (k:ks)
           splits' = tail splits
           (x:xs) = splits
           f "arm" = Just . armRes
           f "armchar" = Just . armcharRes
           f "armr" = Just . armrRes
           f _ = \ _ -> Nothing
           px =  f x $ intercalate ":" xs
           rdfuri [] = error "Trying to parse empty string as URI."
           rdfuri ('>':[]) = []
           rdfuri (_:[]) = error "Malformed URL in RDF.  No closing >."
           rdfuri (u:us) = u:rdfuri us
           uri = rdfuri ks
           tl Nothing = Right "Parser error: Could not parse URI."
           tl (Just xx) = Left $ toRDFLabel xx

