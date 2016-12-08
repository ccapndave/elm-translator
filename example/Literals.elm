module Literals exposing (..)

import Basics.Extra exposing ((=>))
import Dict
import Translations exposing (Translations)

type Literal
  = Increment
  | Decrement
  | TheCount Int
  | TheLanguage { lang : String }


defaultTranslations : Translations
defaultTranslations =
  Dict.fromList
    [ "Increment" => "... inc ..."
    , "Decrement" => "... sub ..."
    , "TheCount" => "... {count} ...|... {count} ..."
    , "TheLanguage" => "... {lang} ..."
    ]
