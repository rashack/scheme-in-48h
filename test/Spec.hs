import Control.Monad
import Parser
import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck as QC
import Text.Parsec

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [properties, unitTests]

properties :: TestTree
properties = testGroup "Properties" [qcProps]


pAtom     = parse parseAtom         "atom err"
pStr      = parse parseString       "string err"
pList     = parse parseList         "list err"
pPair     = parse parseDottedList   "pair err"
pNum      = parse parseNumber       "number err"
pRadixNum = parse parseRadixNumber  "radix number err"
pExpr     = parse parseExpr         "expression err"

unitTests = testGroup "Unit tests"
  [ testCase "Simple atom is parsed" $
    (Right (Atom "foo")) @=? (pAtom "foo")

  , testCase "Boolean true is parsed" $
    (Right (Bool True)) @=? (pAtom "#t")
  , testCase "Boolean false is parsed" $
    (Right (Bool False)) @=? (pAtom "#f")

  , testCase "Simple string is parsed" $
    (Right (String "str")) @=? (pStr "\"str\"")
  , testCase "String with escaped quote is parsed" $
    (Right (String "st\"r")) @=? (pStr "\"st\\\"r\"")


  , testCase "Number is parsed" $
    (Right (Number 1337)) @=? (pNum "1337")
  , testCase "Base 16 number is parsed" $
    (Right (Number 255)) @=? (pRadixNum "#xff")

  , testCase "List is parsed" $
    (Right (List [Atom "f", Atom "x"])) @=? (pList "f x")

  , testCase "Dotted list is parsed" $
    (Right (DottedList [Atom "id"] $ Number 7)) @=? (pPair "id . 7")

  , testCase "Expression is parsed" $
    (Right (List [Atom "e", Number 2, Atom "x"])) @=? (pExpr "(e 2 x)")
  ]

qcProps = testGroup "(checked by QuickCheck)"
  [ QC.testProperty "An atom is parsed" $
    forAll atomString (\s -> pAtom s == Right (Atom s))
  , QC.testProperty "A string is parsed" $
    forAll stringString (\s -> pStr ("\"" ++ s ++ "\"") == Right (String s))
  ]

-- from https://wiki.haskell.org/QuickCheck_as_a_test_set_generator
neStringOf :: [a] -> [a] -> Gen [a]
neStringOf charsStart charsRest =
  do s <- elements charsStart
     r <- listOf' $ elements charsRest
     return (s:r)

listOf' :: Gen a -> Gen [a]
listOf' gen = sized $ \n ->
  do k <- choose (0, n)
     vectorOf' k gen

vectorOf' :: Int -> Gen a -> Gen [a]
vectorOf' k gen = sequence [ gen | _ <- [1..k] ]

instance Arbitrary LispVal where
  arbitrary = liftM Atom atomString

--    n <- choose $ oneof "abc"
--    return  $ Atom n

atomString :: Gen String
atomString = neStringOf letters $ letters ++ symbols

-- TODO: expand to include escaped characters
stringString :: Gen String
stringString = listOf $ elements $ letters ++ symbols

--prop_number n = parse parseNumber "number" n == Right (Number n)

-- quickCheck (prop_atom :: String -> Bool)
-- generate arbitrary :: IO LispVal
-- sample atomString