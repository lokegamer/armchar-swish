-----------------------------------------------------------------------------
-- |
-- Module      :  Main
-- Copyright   :  (c) 2023: Hans Georg Schaathun <hg+gamer@schaathun.net>
-- License     :  see LICENSE
--
-- Maintainer  :  hg+gamer@schaathun.net
--
-----------------------------------------------------------------------------

module Main where

import System.Environment
import System.Console.GetOpt

import ArM.BasicIO
import ArM.Debug.Time
import ArM.Char.Character
import ArM.Char.Markdown

import Data.Aeson (decode)

-- import qualified Data.Text as T
import Data.Maybe (fromJust)

import qualified Data.ByteString.Lazy as LB

data Options = Options 
  { sagaFile :: Maybe String
  , charFile :: Maybe String
  , outFile  :: Maybe String
  , jsonFile :: Maybe String
  , debugFile  :: Maybe String
  , seasonFile  :: Maybe String
  , advanceSeason  :: Maybe String
} deriving (Show)
defaultOptions :: Options
defaultOptions = Options 
  { sagaFile = Just "Test/saga.ttl"
  , charFile = Nothing
  , outFile  = Nothing
  , jsonFile  = Nothing
  , debugFile  = Nothing
  , seasonFile  = Nothing
  , advanceSeason  = Nothing
}


options :: [ OptDescr (Options -> Options) ]
options =
    [ Option ['o']     ["output"]  (ReqArg 
            (\arg opt -> opt { outFile = Just arg })
            "FILE") "output file"
    , Option ['c']     ["character"] (ReqArg 
            (\arg opt -> opt { charFile = Just arg })
            "FILE") "character file"
    , Option ['t']     ["advance-to"] (ReqArg 
            (\arg opt -> opt { advanceSeason = Just arg })
            "SEASON") "advance to "
    , Option ['T']     ["sheet"] (ReqArg 
            (\arg opt -> opt { seasonFile = Just arg })
            "FILE") "output file for current character sheet"
    , Option ['s']     ["saga"] (ReqArg 
            (\arg opt -> opt { sagaFile = Just arg })
            "FILE") "saga file"
    , Option ['j']     ["json"] (ReqArg 
            (\arg opt -> opt { jsonFile = Just arg })
            "FILE") "JSON output file"
    , Option ['O']     ["debug-output"] (ReqArg 
            (\arg opt -> opt { debugFile = Just arg })
            "FILE") "debug output"
    ]

armcharOpts :: [String] -> IO (Options, [String])
armcharOpts argv =
      case getOpt Permute options argv of
         (o,n,[]  ) -> return (foldl (flip id) defaultOptions o, n)
         (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
     where header = "Usage: armchar [OPTION...] "

main :: IO ()
main = do 
     putStrLn "Starting: armchar ..."
     printTime
     args <- getArgs
     (opt,n) <- armcharOpts args
     putStrLns n
     putStrLn $ "Options: " ++ show opt

     main' opt

main' :: Options -> IO ()
main' opts | charFile opts /= Nothing = do 
     putStrLn $ "Reading file " ++ fn
     t <- LB.readFile fn
     let char = fromJust $ ( decode t  :: Maybe Character )
     let cs = prepareCharacter char
     writeMaybeFile ( debugFile opts ) $ printMD char
     writeMaybeFile ( outFile opts ) $ printMD cs
     writeMaybeJSON ( jsonFile opts ) cs 
     return ()
   where fn = fromJust $ charFile opts
main' _ | otherwise = error "Not implemented!" 
