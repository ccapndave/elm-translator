module TranslatorExample exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Dict
import Basics.Extra exposing ((=>))
import Translator exposing (Translator)
import Translations exposing (Translations)
import Literals

main : Program Never Model Msg
main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


type alias Model =
  { count : Int
  , lang : Maybe String
  , translator : Translator
  }


init : (Model, Cmd Msg)
init =
  { count = 0
  , lang = Nothing
  , translator = Translator.makeDefaultTranslator Literals.defaultTranslations
  } ! []


type Msg
  = Increment
  | Decrement
  | ChangeToEnglish
  | ChangeToFrench


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      { model | count = model.count + 1 } ! []

    Decrement ->
      { model | count = model.count - 1 } ! []

    ChangeToEnglish ->
      let
        -- This would probably be loaded from a json file at runtime and decoded into a Translations,
        -- but we will just create a Translations by hand for the purposes of this example.
        englishTranslations : Translations
        englishTranslations =
          Dict.fromList
            [ "Increment" => "Increment"
            , "Decrement" => "Decrement"
            , "TheCount" => "There is only one!|There are {count} of them"
            , "TheLanguage" => "We are speaking {lang}"
            ]
      in
      { model
      | lang = Just "English"
      , translator = Translator.updateTranslations englishTranslations model.translator
      } ! []

    ChangeToFrench ->
      let
        -- This would probably be loaded from a json file at runtime and decoded into a Translations,
        -- but we will just create a Translations by hand for the purposes of this example.
        frenchTranslations : Translations
        frenchTranslations =
          Dict.fromList
            [ "Increment" => "Incrément"
            , "Decrement" => "Décrément"
            , "TheCount" => "Il y a juste un!|Il y a {count}"
            , "TheLanguage" => "Nous parlons {lang}"
            ]
      in
      { model
      | lang = Just "Français"
      , translator = Translator.updateTranslations frenchTranslations model.translator
      } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


view : Model -> Html Msg
view model =
  div []
    [ button
        [ onClick Decrement ]
        [ Translator.text model.translator Literals.Decrement ]
    , div
        []
        [ Translator.text model.translator <| Literals.TheCount model.count ]
    , button
        [ onClick Increment ]
        [ Translator.text model.translator Literals.Increment ]
    , Html.br [] []
    , Html.br [] []
    , div
        []
        [ Translator.text model.translator <| Literals.TheLanguage { lang = model.lang |> Maybe.withDefault "none" } ]
    , button
        [ onClick ChangeToEnglish ]
        [ text "English" ]
    , button
        [ onClick ChangeToFrench ]
        [ text "Français" ]
    ]
