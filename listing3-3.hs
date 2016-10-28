module Main where
import Control.Monad
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
  c <- noneOf "\""
  return [c]

escapedChar :: Parser String
escapedChar = do
  char '\\'
  c <- oneOf "\""
  return [c]

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
