module Translations exposing
  ( Translations
  , decoder
  , encode
  )

{-| This represents a set of translations in a language.

@docs Translations, decoder, encode
-}

import Json.Decode as JD exposing (Decoder, field)
import Json.Encode as JE exposing (Value)
import Dict exposing (Dict)

{-|
-}
type alias Translations = Dict String String


{-|
-}
decoder : Decoder Translations
decoder =
  JD.dict JD.string


{-|
-}
encode : Translations -> Value
encode translations =
  let
    -- https://github.com/elm-lang/core/issues/484 and https://github.com/elm-lang/core/issues/322)
    dictEncoder : (a -> Value) -> Dict String a -> Value
    dictEncoder encode dict =
      Dict.toList dict
        |> List.map (\(k, v) -> (k, encode v))
        |> JE.object
  in
  dictEncoder JE.string translations
