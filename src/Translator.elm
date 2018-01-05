module Translator exposing
  ( Translator
  , makeDefaultTranslator
  , updateTranslations
  , getTranslations
  , decoderFromTranslationsWithDefault
  , decoderToUpdateTranslations
  , trans
  , transString
  , text
  , placeholder
  )

{-| A package to provide type safe internationalisation, where translations can be loaded at
runtime.  Default translations, substitutions and pluralization are supported.

Substitutions are implemented by surrounding the literal in braces:

    "MyNameIs": "Je m'appelle {name}"

Pluralization is implemented by having the singular case on the left of the pipe symbol, and all
other cases on the right.  The number can be substituted using `{count}`.

    "MyAge": "I am only one year old|I'm {count} years old"

See the `example/` directory for an example of the package being used.

## Building Translators
@docs Translator, makeDefaultTranslator, updateTranslations, getTranslations, decoderFromTranslationsWithDefault, decoderToUpdateTranslations

## Using Translators
@docs trans, transString, text, placeholder
-}

import Json.Decode as JD exposing (Decoder, field)
import Basics.Extra exposing ((=>))
import Dict exposing (Dict)
import Regex exposing (regex)
import Reflect exposing (typeToName, typeParameterRecordToDict, typeParameterToInt)
import Html exposing (Html, Attribute)
import Html.Attributes
import Translations exposing (Translations)

{-| A Translator contains all the required information to translate strings into other languages.
-}
type alias Translator =
  { defaultTranslations : Translations
  , translations : Maybe Translations
  }


{-| This creates a Json Decoder that will decode Json of the form:

    {
        "Yes": "Oui",
        "No": "Non"
    }

into a valid Translator that can be used with the translation functions in this package.  You
need to provide a Translations parameter which contains the default translations, in case a
translation can't be matched.
-}
decoderFromTranslationsWithDefault : Translations -> Decoder Translator
decoderFromTranslationsWithDefault defaultTranslations =
  JD.map2 Translator
    (JD.succeed defaultTranslations)
    (JD.nullable Translations.decoder)


{-| This creates a Json Decoder that will decode Json of the form:

    {
        "Yes": "Oui",
        "No": "Non"
    }

into a valid Translator that can be used with the translation functions in this package.  You
need to provide a Translator parameter which contains an existing translator; the default translations
will be kept from this Translator.
-}
decoderToUpdateTranslations : Translator -> Decoder Translator
decoderToUpdateTranslations translator =
  JD.map2 Translator
    (JD.succeed translator.defaultTranslations)
    (JD.nullable Translations.decoder)


{-| This creates a Translator with the given default Translations, but no loaded Translations.
Typically this would be used when initializing your program's Model to make sure there are some
translations on startup.
-}
makeDefaultTranslator : Translations -> Translator
makeDefaultTranslator defaultTranslations =
  Translator defaultTranslations Nothing


{-| Update an existing Translator with the given loaded Translations.  Typically this would be
used to update an existing Translator when you have loaded some Translations at runtime.
-}
updateTranslations : Translations -> Translator -> Translator
updateTranslations translations translator =
  { translator
  | translations = Just translations
  }


{-| Get the translations out of the Translator (if there are any).
-}
getTranslations : Translator -> Maybe Translations
getTranslations =
  .translations


{-| Given an id and a Translator, translate to a String.  This can never fail, and in the event
of being unable to match in either the loaded or default literals this will fall back to "...".
This supports substitutions and pluralization.

Substitutions and pluralization are supported (see the top-level package doumentation).
-}
trans : literal -> Translator -> String
trans literal translator =
  let
    -- Choose a translation, or default to "..." if we don't have one
    chosenTranslation: String
    chosenTranslation =
      let
        -- Get the translator from translations (if we can)
        translation : Maybe String
        translation =
          translator.translations
            |> Maybe.andThen (Dict.get <| typeToName literal)

        -- Get the fallback translation from defaultTranslations (if we can)
        defaultTranslation : Maybe String
        defaultTranslation =
          translator.defaultTranslations
            |> Dict.get (typeToName literal)
      in
      case (translation, defaultTranslation) of
        (Just t, _) ->
          t

        (Nothing, Just t) ->
          t

        (Nothing, Nothing) ->
          "..."

    -- Choose the substitutions by using reflection
    stringRecordParameter : Result String (Dict String String)
    stringRecordParameter =
      typeParameterRecordToDict JD.string literal

    intParameter : Result String Int
    intParameter =
      typeParameterToInt literal

    chosenSubstitutions : Dict String String
    chosenSubstitutions =
      case (stringRecordParameter, intParameter) of
        (Ok dict, _) ->
          dict

        (Err _, Ok count) ->
          Dict.fromList [ "count" => toString count ]

        otherwise ->
          Dict.empty
  in
  chosenTranslation
    |> substitute chosenSubstitutions
    |> pluralize (Result.toMaybe intParameter)


{-| This is identical to trans, except that it takes the name of the literal as a String
instead of the Literal itself.  This is useful when the literal's name is loaded dynamically.
Because we don't have access to the type constructor this doesn't support substitutions.
-}
transString : String -> Translator -> String
transString literalString translator =
  let
    -- Get the translator from translations (if we can)
    translation : Maybe String
    translation =
      translator.translations
        |> Maybe.andThen (Dict.get literalString)

    -- Get the fallback translation from defaultTranslations (if we can)
    defaultTranslation : Maybe String
    defaultTranslation =
      translator.defaultTranslations
        |> Dict.get literalString
  in
  case (translation, defaultTranslation) of
    (Just t, _) ->
      t

    (Nothing, Just t) ->
      t

    (Nothing, Nothing) ->
      "..."


{-| Apply any substitutions by replacing any `{key}`s in the translated string with their `value`s
-}
substitute : Dict String String -> String -> String
substitute substitutions translation =
  let
    substituteItem : String -> String -> String -> String
    substituteItem key value str =
      Regex.replace Regex.All (regex <| "{" ++ key ++ "}") (always value) str
  in
  substitutions
    |> Dict.foldl substituteItem translation


{-| Deal with pluralization based on the given count
-}
pluralize : Maybe Int -> String -> String
pluralize count translation =
  let
    (singularClause, pluralClause) =
      case (String.split "|" translation) of
        [ singularClause, pluralClause ] ->
          (singularClause, pluralClause)

        otherwise ->
          ("", "")
  in
  case count of
    Just 1 ->
      singularClause

    Just _ ->
      pluralClause

    Nothing ->
      translation


{-| A translated version of Html.text for use directly in an Elm view
-}
text : Translator -> literal -> Html msg
text translator literal =
  translator
    |> trans literal
    |> Html.text


{-| A translated version of Html.Attributes.placeholder for use directly in an Elm view
-}
placeholder : Translator -> literal -> Attribute msg
placeholder translator literal =
  translator
    |> trans literal
    |> Html.Attributes.placeholder
