module Main where
import Control.Monad
import Data.Char (chr)
import System.Environment
import Text.ParserCombinators.Parsec hiding (spaces)

symbol :: Parser Char
symbol = oneOf "!$%&|*+-/:<=>?@^_~#"

spaces :: Parser ()
spaces = skipMany1 space

data LispVal = Atom String
             | List [LispVal]
             | DottedList [LispVal] LispVal
             | Number Integer
             | String String
             | Bool Bool
  deriving (Show)

parseString :: Parser LispVal
parseString = do char '"'
                 x <- many parseStrStr
                 char '"'
                 return $ String $ foldl (++) "" x

parseStrStr :: Parser String
parseStrStr = escapedChar
          <|> normalChar

normalChar :: Parser String
normalChar = do
  c <- noneOf escapables
  return [c]

escapedChar :: Parser String
escapedChar = do
  char '\\'
  c <- oneOf escapables
  return [chr $ c2i c]

escapables = "0abtnvfr\"\\"

c2i '0'  =  0 -- NUL (null)
c2i 'a'  =  7 -- BEL (bell)
c2i 'b'  =  8 -- BS  (backspace)
c2i 't'  =  9 -- HT  (horizontal tab)
c2i 'n'  = 10 -- LF  (new line)
c2i 'v'  = 11 -- VT  (vertical tab)
c2i 'f'  = 12 -- FF  (form feed)
c2i 'r'  = 13 -- CR  (carriage return)
c2i '\"' = 34
c2i '\\' = 92

parseAtom :: Parser LispVal
parseAtom = do first <- letter <|> symbol
               rest <- many (letter <|> digit <|> symbol)
               let atom = [first] ++ rest
               return $ case atom of
                          "#t" -> Bool True
                          "#f" -> Bool False
                          otherwise -> Atom atom

parseNumber :: Parser LispVal
parseNumber = liftM (Number . read) $ many1 digit
---- alt 1
-- parseNumber = many1 digit >>= \ds -> return $ (Number . read) ds
---- alt 2
-- parseNumber = do
--   ds <- many1 digit
--   return $ (Number . read) ds

parseExpr :: Parser LispVal
parseExpr = parseAtom
        <|> parseString
        <|> parseNumber

readExpr :: String -> String
readExpr input = case parse parseExpr "lisp" input of
    Left err -> "No match: " ++ show err
    Right val -> "Found value" ++ show val

main :: IO ()
main = do args <- getArgs
          putStrLn (readExpr (args !! 0))
