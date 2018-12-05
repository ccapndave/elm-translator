module Translations exposing (Translations, decoder, encode)

{-| This represents a set of translations in a language.

@docs Translations, decoder, encode

-}

import Dict exposing (Dict)
import Json.Decode as JD exposing (Decoder, field)
import Json.Encode as JE exposing (Value)


{-| -}
type alias Translations =
    Dict String String


{-| -}
decoder : Decoder Translations
decoder =
    JD.dict JD.string


{-| -}
encode : Translations -> Value
encode translations =
    JE.dict identity JE.string translations
