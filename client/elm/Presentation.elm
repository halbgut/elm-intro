module Presentation where

import Signal exposing (Address, map, merge)
import Keyboard
import List exposing ((::))
import Html exposing (Html, div, h1, article, fromElement, text, p)
import Html.Attributes exposing (style, class)
import Html.Events exposing (onKeyDown)
import Markdown
import Effects exposing (Effects)
import Http
import Json.Decode exposing ((:=))
import Task exposing (Task)
import StartApp

type alias Model =
  { slide : Int
  , slides : List Slide
  }

type alias Slide =
  { title : String
  , content : String
  }

type Action = NoOp
  | PrevSlide
  | NextSlide
  | AddSlides (Maybe (List Slide))

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NoOp ->
      ( model
      , Effects.none
      )

    NextSlide ->
      ( { model |
          slide = model.slide+1
        }
      , Effects.none
      )

    PrevSlide ->
      ( { model |
          slide = model.slide-1
        }
      , Effects.none
      )

    AddSlides maybeSlides ->
      ( { model |
          slides = model.slides ++ (Maybe.withDefault [] maybeSlides)
        }
      , Effects.none
      )

getSlides : String -> Effects Action
getSlides url =
  Http.get slidesDecoder url
    |> Task.toMaybe
    |> Task.map AddSlides
    |> Effects.task

slidesDecoder : Json.Decode.Decoder (List Slide)
slidesDecoder =
  Json.Decode.list
    <| Json.Decode.object2 Slide
      ("title" := Json.Decode.string)
      ("content" := Json.Decode.string)

keySignal : Signal Action
keySignal =
  map
    ( \key ->
      if key == 39
        then NextSlide
      else if key == 37
        then PrevSlide
        else NoOp
    )
    Keyboard.presses

renderSlide : Int -> Slide -> Html
renderSlide i slide =
  article
    [ class "slide"
    , style
      [ ("width", "100vw")
      , ("height", "100vh")
      , ("display", "inline-block")
      ]
    ]
    [ h1
      []
      [ text slide.title ]
    , div
      []
      [ fromElement <| Markdown.toElement slide.content ]
    ]

translateX : Int -> String
translateX i =
  "translateX(" ++ toString i ++ "vw)"

init : (Model, Effects Action)
init =
  ( { slide = 0
    , slides = []
    }
  , getSlides "/slides"
  )

view : Address Action -> Model -> Html
view address model =
  div
    []
    [ div
      [ style
          [ ("position", "absolute")
          , ("white-space", "nowrap")
          , ("transform"
            , translateX
                <| negate
                <| model.slide * 100
            )
          , ("height", "100vh")
          ]
      ]
      <| List.indexedMap renderSlide model.slides
    , p
      [ style
        [ ("position", "fixed")
        , ("bottom", "0")
        , ("left", "0")
        ]
      ]
      [ text <| toString model.slide ]
    ]

app =
  StartApp.start
    { init = init
    , view = view
    , update = update
    , inputs = [keySignal]
    }

main : Signal Html
main =
  app.html

port tasks : Signal (Task Effects.Never ())
port tasks =
  app.tasks
