module Translator exposing
    ( Literal
    , makeLiteral, makeLiteralWithOptions
    , defaultTranslator, addTranslations, updateTranslations
    , trans, text, placeholder
    )

{-| This is package to provide type safe internationalisation, where translations can be loaded at
runtime. Default translations, substitutions and pluralization are supported.

Substitutions are implemented by surrounding the literal in braces:

    {
      "MyNameIs": "Je m'appelle {name}"
    }

Pluralization is implemented by having the singular case on the left of the pipe symbol, and all
other cases on the right. The number can be substituted using `{count}`.

    {
      "MyAge": "I am only one year old|I'm {count} years old"
    }

@docs Literal
@docs makeLiteral, makeLiteralWithOptions
@docs defaultTranslator, addTranslations, updateTranslations
@docs trans, text, placeholder

-}

import Dict exposing (Dict)
import Html exposing (Attribute, Html)
import Html.Attributes
import Regex
import Translations exposing (Translations)


{-| This represents a literal that can be translated.
-}
type Literal
    = Literal LiteralData


type alias LiteralData =
    { id : String
    , default : Maybe String
    , substitutions : Dict String String
    , count : Maybe Int
    }


type Translator
    = Translator (List Translations)


{-| An empty translator. The only translations this will be able to do are the defaults
specified in the literals (hence why it is called `defaultTranslator`).
-}
defaultTranslator : Translator
defaultTranslator =
    Translator []


{-| Add a translation dictionary to a translator.
-}
addTranslations : Translations -> Translator -> Translator
addTranslations translations (Translator translationDicts) =
    Translator (translations :: translationDicts)


{-| Update the translation dictionary at the head of the stack. If there are none
then set this as the only translation dictionary.
-}
updateTranslations : Translations -> Translator -> Translator
updateTranslations translations (Translator translationDicts) =
    case translationDicts of
        [] ->
            Translator [ translations ]

        firstTranslations :: xs ->
            Translator (translations :: xs)


{-| Given the id of the literal in the translations, make a Literal that can be used
for doing a translation.
-}
makeLiteral : String -> Literal
makeLiteral id =
    makeLiteralWithOptions id Nothing Dict.empty Nothing


{-| Given the id of the literal in the translations, make a Literal that can be used
for doing a translation. This also allows you to specify a default translation, substitutions
and a count for pluralisation.
-}
makeLiteralWithOptions : String -> Maybe String -> Dict String String -> Maybe Int -> Literal
makeLiteralWithOptions id default substitutions count =
    Literal (LiteralData id default substitutions count)


findTranslation : Literal -> Translator -> String
findTranslation ((Literal { id, default }) as literal) (Translator translations) =
    case translations of
        [] ->
            default |> Maybe.withDefault "..."

        firstTranslationDict :: xs ->
            case Dict.get id firstTranslationDict of
                Just translation ->
                    translation

                Nothing ->
                    findTranslation literal (Translator xs)


{-| Given a Literal, translate to a String. This can never fail, and in the event
of being unable to match in either the loaded or default literals this will fall back to "...".
This supports substitutions and pluralization.
-}
trans : Literal -> Translator -> String
trans ((Literal { id, default, substitutions, count }) as literal) translator =
    findTranslation literal translator
        |> substitute substitutions
        |> pluralize count


{-| A translated version of Html.text for use directly in an Elm view
-}
text : Translator -> Literal -> Html msg
text translator literal =
    translator
        |> trans literal
        |> Html.text


{-| A translated version of Html.Attributes.placeholder for use directly in an Elm view
-}
placeholder : Translator -> Literal -> Attribute msg
placeholder translator literal =
    translator
        |> trans literal
        |> Html.Attributes.placeholder


{-| Apply any substitutions by replacing any `{key}`s in the translated string with their `value`s
-}
substitute : Dict String String -> String -> String
substitute substitutions translation =
    let
        substituteItem : String -> String -> String -> String
        substituteItem key value str =
            Regex.fromString ("{\\s*" ++ key ++ "\\s*}")
                |> Maybe.map (\regex -> Regex.replace regex (\_ -> value) str)
                |> Maybe.withDefault str
    in
    substitutions
        |> Dict.foldl substituteItem translation


{-| Deal with pluralization based on the given count
-}
pluralize : Maybe Int -> String -> String
pluralize count translation =
    let
        ( singularClause, pluralClause ) =
            case String.split "|" translation of
                [ s, p ] ->
                    ( s, p )

                otherwise ->
                    ( "", "" )
    in
    case count of
        Just 1 ->
            singularClause |> substitute (Dict.fromList [ ( "count", "1" ) ])

        Just n ->
            pluralClause |> substitute (Dict.fromList [ ( "count", String.fromInt n ) ])

        Nothing ->
            translation
