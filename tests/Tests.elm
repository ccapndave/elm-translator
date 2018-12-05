module Tests exposing (all)

import Dict
import Expect
import Literals
import Test exposing (..)
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


translationsTest : Test
translationsTest =
    let
        translator =
            defaultTranslator
                |> updateTranslations (Dict.fromList [ ( "Yes", "Oui" ) ])
    in
    test "should work for normal translations" <|
        \() ->
            Expect.equal (trans Literals.yes translator) "Oui"


defaultTranslationsTest : Test
defaultTranslationsTest =
    test "should work with the fallback (default) translations" <|
        \() ->
            Expect.equal (trans Literals.no defaultTranslator) "Non"


noMatchTest : Test
noMatchTest =
    test "should return ... if there is no match" <|
        \() ->
            Expect.equal (trans Literals.yes defaultTranslator) "..."


substitutionTest : Test
substitutionTest =
    let
        translator =
            defaultTranslator
                |> updateTranslations (Dict.fromList [ ( "MyNameIs", "Je m'appelle {name}" ) ])
    in
    test "should substitute values" <|
        \() ->
            Expect.equal (trans (Literals.myNameIs { name = "Dave" }) translator) "Je m'appelle Dave"


pluralizationTest : Test
pluralizationTest =
    let
        translator =
            defaultTranslator
                |> updateTranslations (Dict.fromList [ ( "ThereAreNPeople", "Il y a {count} personne|Il y a {count} personnes" ) ])
    in
    describe "should pluralize"
        [ test "the single case" <|
            \() ->
                Expect.equal (trans (Literals.thereAreNPeople 1) translator) "Il y a 1 personne"
        , test "the multiple case" <|
            \() ->
                Expect.equal (trans (Literals.thereAreNPeople 5) translator) "Il y a 5 personnes"
        ]


everythingTest : Test
everythingTest =
    describe "should default, substitute and pluralise"
        [ test "the single case" <|
            \() ->
                Expect.equal (trans (Literals.everything 1 { firstName = "Dave" }) defaultTranslator) "Dave is 1"
        , test "the multiple case" <|
            \() ->
                Expect.equal (trans (Literals.everything 5 { firstName = "Dave" }) defaultTranslator) "Dave is 5 years old"
        ]
