{-# LANGUAGE CPP #-}
-- | Collection of helpers to use with Text.XML.Stream.Parse parsers.
--
-- > let sink = flaxTag "MethodNameResponse"
-- >          $ flaxTag "MethodNameResult" $ do
-- >              info <- flaxTag "Info" $ do
-- >                          q <- readTag "quantity"
-- >                          b <- readTag "balance"
-- >                          return $ Info q b
-- >              rc <- readTag "ResponseCode"
-- >              return (rc, info)

module Network.SOAP.Parsing.Stream
    ( -- * Tags
      laxTag, flaxTag
      -- * Content
    , laxContent, flaxContent
    , readContent, readTag
      -- * Types to use in custom parser sinks
    , Sink, Event
    ) where

#if MIN_VERSION_conduit(1,1,0)
import Control.Monad.Catch (MonadThrow)
#endif
import Data.Conduit
import Data.XML.Types (Event)

import           Text.XML (Name(..))
import qualified Text.XML.Stream.Parse as XSP

import           Data.Text (Text, unpack)

-- | Namespace- and attribute- ignorant tagNoAttr.
laxTag :: (MonadThrow m) => Text -> Sink Event m a -> Sink Event m (Maybe a)
#if MIN_VERSION_xml_conduit(1,5,0)
laxTag ln = XSP.tag' (XSP.matching $ (== ln) . nameLocalName) XSP.ignoreAttrs . const
#else
laxTag ln = XSP.tagPredicate ((== ln) . nameLocalName) XSP.ignoreAttrs . const
#endif

-- | Non-maybe version of laxTag/tagNoAttr.
flaxTag :: (MonadThrow m) => Text -> Sink Event m a -> Sink Event m a
flaxTag ln s = XSP.force ("got no " ++ show ln) $ laxTag ln s

laxContent :: (MonadThrow m) => Text -> Sink Event m (Maybe Text)
laxContent ln = laxTag ln XSP.content

flaxContent :: (MonadThrow m) => Text -> Sink Event m Text
flaxContent ln = flaxTag ln XSP.content

-- | Unpack and read a current tag content.
readContent :: (Read a, MonadThrow m) => Sink Event m a
readContent = fmap (read . unpack) XSP.content

-- | Unpack and read tag content by local name.
readTag :: (Read a, MonadThrow m) => Text -> Sink Event m a
readTag n = flaxTag n readContent
