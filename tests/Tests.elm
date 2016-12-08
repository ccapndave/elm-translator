module Tests exposing (..)

import Test exposing (..)
import Expect
import Dict
import Basics.Extra exposing ((=>))
import Translator exposing (..)

all : Test
all =
  describe "Translations"
    [ translationsTest
    , defaultTranslationsTest
    , noMatchTest
    , substitutionTest
    , pluralizationTest
    ]


type Literal
  = Yes
  | No
  | MyNameIs { name : String }
  | ThereAreNPeople Int


translationsTest : Test
translationsTest =
  let
    translator =
      makeDefaultTranslator Dict.empty
        |> updateTranslations (Dict.fromList [ "Yes" => "Oui" ])
  in
  test "should work for normal translations" <|
    \() ->
      Expect.equal (trans Yes translator) "Oui"


defaultTranslationsTest : Test
defaultTranslationsTest =
  let
    translator =
      makeDefaultTranslator (Dict.fromList [ "Yes" => "Oui" ])
  in
  test "should work with the fallback (default) translations" <|
    \() ->
      Expect.equal (trans Yes translator) "Oui"


noMatchTest : Test
noMatchTest =
  let
    translator =
      makeDefaultTranslator Dict.empty
  in
  test "should return ... if there is no match" <|
    \() ->
      Expect.equal (trans Yes translator) "..."


substitutionTest : Test
substitutionTest =
  let
    translator =
      makeDefaultTranslator Dict.empty
        |> updateTranslations (Dict.fromList [ "MyNameIs" => "Je m'appelle {name}" ])
  in
  test "should substitute values" <|
    \() ->
      Expect.equal (trans (MyNameIs { name = "Dave" }) translator) "Je m'appelle Dave"


pluralizationTest : Test
pluralizationTest =
  let
    translator =
      makeDefaultTranslator Dict.empty
        |> updateTranslations (Dict.fromList [ "ThereAreNPeople" => "Il y a {count} personne|Il y a {count} personnes" ])
  in
  describe "should pluralize"
    [ test "the single case" <|
        \() ->
          Expect.equal (trans (ThereAreNPeople 1) translator) "Il y a 1 personne"
    , test "the other case" <|
        \() ->
          Expect.equal (trans (ThereAreNPeople 5) translator) "Il y a 5 personnes"
    ]
