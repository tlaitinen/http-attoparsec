{-# LANGUAGE OverloadedStrings #-}
module Network.HTTP.Attoparsec
( 
 byteRangesParser,
 parseByteRanges
)
where
import Network.HTTP.Types.Header

import qualified Data.ByteString                as B
import qualified Data.Attoparsec.ByteString.Char8  as A8
import           Control.Applicative ((<|>), (<$>))

byteRangesParser :: A8.Parser ByteRanges
byteRangesParser = do
    _ <- A8.string "bytes="
    br <- range
    rest <- maybeMoreRanges 
    return $ br:rest
    where
        range = rangeFromTo <|> rangeSuffix
        rangeFromTo = do
            f <- A8.decimal
            _ <- A8.char '-'
            mt <- Just <$> A8.decimal <|> return Nothing
            
            return $ case mt of
                Just t -> ByteRangeFromTo f t
                Nothing -> ByteRangeFrom f
        rangeSuffix = do
            _ <- A8.char '-'
            s <- A8.decimal
            return $ ByteRangeSuffix s
        maybeMoreRanges = moreRanges <|> return []
        moreRanges = do
            _ <- A8.char ','
            r <- range
            rest <- maybeMoreRanges
            return $ r:rest
       
parseByteRanges :: B.ByteString -> Maybe ByteRanges
parseByteRanges bs = case A8.parseOnly byteRangesParser bs of
    Left _ -> Nothing
    Right br -> Just br
