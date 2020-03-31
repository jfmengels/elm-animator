module Loading exposing (main)

{-| Animating loading states!

It's pretty common to have a type, usually called RemoteData, to represent a piece of data that's been requested from the server.

It generally looks something like this:

    type RemoteData error data
        = NotAsked
        | Loading
        | Failure error
        | Success data

This example will show you how to:

1.  Animate a "resting" state, so that when we're at a state of `Loading`, a a loading animation is occurring.
2.  Animate content that's already been deleted! In this case we can show the previously retrieved comment, even whil we're in a loading state.
3.  How to debug animations with `Animator.Css.explain`. This will show you a bounding box for an element, as well as it's center of rotation.

Search for (1), (2), and (3) respectively to see the code!

-}

import Animator
import Animator.Css
import Animator.Inline
import Browser
import Color
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events as Events
import Process
import Task
import Time


type RemoteData error data
    = NotAsked
    | Loading
    | Failure error
    | Success data


type alias Model =
    { comment :
        Animator.Timeline (RemoteData String String)
    }


main =
    Browser.document
        { init =
            \() ->
                ( { comment =
                        Animator.init NotAsked
                  }
                , Cmd.none
                )
        , view = view
        , update = update
        , subscriptions =
            \model ->
                animator
                    |> Animator.toSubscription Tick model
        }


{-| -}
animator : Animator.Animator Model
animator =
    Animator.animator
        -- *NOTE*  We're using `the Animator.Css.with` instead of the normal one.
        -- This one only needs to update
        |> Animator.Css.with
            .comment
            (\newComment model ->
                { model | comment = newComment }
            )


type Msg
    = Tick Time.Posix
    | AskServerForNewComment
    | NewCommentFromServer String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( model
                |> Animator.update newTime animator
            , Cmd.none
            )

        AskServerForNewComment ->
            ( { model
                | comment =
                    model.comment
                        |> Animator.to Loading
              }
            , Task.perform (always (NewCommentFromServer "Howdy partner!"))
                (Process.sleep (2 * 1000))
            )

        NewCommentFromServer comment ->
            ( { model
                | comment =
                    model.comment
                        |> Animator.to (Success comment)
              }
            , Cmd.none
            )


view : Model -> Browser.Document Msg
view model =
    { title = "Animator - Loading"
    , body =
        [ Html.node "style"
            []
            [ text """@import url('https://fonts.googleapis.com/css?family=Roboto&display=swap');"""
            ]
        , div
            [ Attr.style "width" "100%"
            , Attr.style "font-size" "48px"
            , Attr.style "user-select" "none"
            , Attr.style "padding" "50px"
            , Attr.style "box-sizing" "border-box"
            , Attr.style "font-family" "'Roboto', sans-serif"
            , Attr.style "padding" "200px"
            ]
            [ div
                [ Attr.style "display" "flex"
                , Attr.style "flex-direction" "column"
                , Attr.style "align-items" "flex-start"
                , Attr.style "justify-content" "center"
                , Attr.style "width" "400px"
                ]
                [ viewComment model.comment
                , Html.div
                    [ Attr.style "display" "flex"
                    , Attr.style "flex-direction" "row"
                    , Attr.style "justify-content" "space-between"
                    , Attr.style "width" "100%"
                    ]
                    [ Html.button
                        [ Attr.style "background-color" pink
                        , Attr.style "padding" "8px 12px"
                        , Attr.style "border" "none"
                        , Attr.style "border-radius" "2px"
                        , Attr.style "color" "white"
                        , Attr.style "cursor" "pointer"
                        , Attr.style "margin-top" "20px"
                        , Events.onClick AskServerForNewComment
                        ]
                        [ Html.text "Load comment" ]
                    ]
                ]
            ]
        ]
    }


pink =
    "rgb(240, 0, 245)"


viewComment comment =
    Animator.Css.div comment
        [ Animator.Css.backgroundColor <|
            \state ->
                case state of
                    Loading ->
                        Color.rgb 0.9 0.9 0.9

                    _ ->
                        Color.rgb 1 1 1
        , Animator.Css.fontColor <|
            \state ->
                case state of
                    Loading ->
                        Color.rgb 0.5 0.5 0.5

                    _ ->
                        Color.rgb 0 0 0
        , Animator.Css.borderColor <|
            \state ->
                case state of
                    Loading ->
                        Color.rgb 0.5 0.5 0.5

                    _ ->
                        Color.rgb 0 0 0
        ]
        [ Attr.style "position" "relative"
        , Attr.style "display" "flex"
        , Attr.style "flex-direction" "column"
        , Attr.style "justify-content" "space-between"
        , Attr.style "font-size" "16px"
        , Attr.style "width" "100%"
        , Attr.style "height" "100px"
        , Attr.style "padding" "24px"
        , Attr.style "box-sizing" "border-box"
        , Attr.style "border" "1px solid black"
        , Attr.style "border-radius" "3px"
        ]
        [ loadingIndicator comment
        , case Animator.current comment of
            NotAsked ->
                Html.div [ Attr.style "color" "#CCC" ] [ Html.text "No comment loaded" ]

            Loading ->
                Html.div []
                    -- (2) - We can still show the previous comment!
                    --       If we're loading a new one, we'll grey it out.
                    [ case Animator.previous comment of
                        Success text ->
                            Html.div
                                [ Attr.style "display" "flex"
                                , Attr.style "flex-direction" "row"
                                , Attr.style "filter" "grayscale(1)"
                                ]
                                [ viewThinking
                                , Html.text text
                                ]

                        _ ->
                            Html.div [] [ Html.text "Loading..." ]
                    ]

            Failure error ->
                Html.div [] [ Html.text error ]

            Success text ->
                Html.div
                    [ Attr.style "display" "flex"
                    , Attr.style "flex-direction" "row"
                    ]
                    [ viewCowboy
                        -- (3) - w have debug
                        { debug = False
                        , timeline = comment
                        }
                    , Html.text text
                    ]
        ]


loadingIndicator : Animator.Timeline (RemoteData error success) -> Html msg
loadingIndicator loading =
    Html.div
        [ Attr.style "display" "flex"
        , Attr.style "width" "100%"
        , Attr.style "height" "100%"
        , Attr.style "left" "0"
        , Attr.style "top" "0"
        , Attr.style "position" "absolute"
        , Attr.style "box-sizing" "border-box"
        , Attr.style "flex-direction" "row"
        , Attr.style "justify-content" "center"
        , Attr.style "align-items" "center"
        ]
        [ viewBlinkingCircle 0.2 loading
        , viewBlinkingCircle 0.3 loading
        , viewBlinkingCircle 0.4 loading
        ]


viewBlinkingCircle offset timeline =
    Animator.Css.div timeline
        [ Animator.Css.opacity <|
            \state ->
                case state of
                    Loading ->
                        -- (1) - When we're loading, use a sine wave to oscillate between 0.05 and 1
                        --       Becase we want multiple blinking circles, we can als "shift" this wave over by some amount.
                        --       A shift of 0 means the value starts at 0.05.
                        --       A shift of 1 would mean the value starts at the "end", at 1.
                        --       Then we tell it to take 700ms for a full loop
                        Animator.wave 0.05 1
                            |> Animator.shift offset
                            |> Animator.loop (Animator.millis 700)

                    _ ->
                        Animator.at 0
        ]
        [ Attr.style "width" "12px"
        , Attr.style "height" "12px"
        , Attr.style "border-radius" "6px"
        , Attr.style "background-color" pink
        , Attr.style "margin-right" "8px"
        ]
        []


viewThinking =
    Html.div
        [ Attr.style "display" "flex"
        , Attr.style "flex-direction" "center"
        , Attr.style "transform" "translateY(-6px)"
        , Attr.style "width" "72px"
        , Attr.style "font-size" "24px"
        , Attr.style "margin-right" "12px"
        , Attr.style "justify-content" "center"
        ]
        [ Html.text "\u{1F914}"
        ]


viewCowboy { debug, timeline } =
    Html.div
        [ Attr.style "display" "flex"
        , Attr.style "transform" "translateY(-6px)"
        , Attr.style "width" "72px"
        , Attr.style "font-size" "24px"
        , Attr.style "margin-right" "12px"
        ]
        [ Animator.Css.div timeline
            -- (3) - Animator.Css.explain True will show you
            --         -> the bounding box for this element
            --         -> the center of rotation, which you can change by setting the origin with transformWith
            --         -> The coordinate system for this element.
            [ Animator.Css.explain debug
            , Animator.Css.opacity <|
                \state ->
                    case state of
                        Success _ ->
                            Animator.at 1

                        _ ->
                            Animator.at 0
            , Animator.Css.transformWith
                { rotationAxis =
                    { x = 0
                    , y = 0
                    , z = 1
                    }
                , origin =
                    Animator.Css.offset
                        -5
                        3
                }
              <|
                \state ->
                    case state of
                        NotAsked ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Loading ->
                            Animator.Css.rotating (Animator.seconds 5)

                        Failure error ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Success text ->
                            fingerGuns 0.5
            ]
            []
            [ Html.text "👉"
            ]
        , Animator.Css.div timeline
            [ Animator.Css.explain debug
            , Animator.Css.transformWith
                { rotationAxis =
                    { x = 0
                    , y = 0
                    , z = 1
                    }
                , origin =
                    Animator.Css.offset
                        0
                        0
                }
              <|
                \state ->
                    case state of
                        NotAsked ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Loading ->
                            Animator.Css.rotating (Animator.seconds 5)

                        Failure error ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Success text ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }
                                |> Animator.Css.lookAt
                                    { x = 0.7
                                    , y = 0.2
                                    , z = 0.8
                                    }
            ]
            []
            [ case Animator.current timeline of
                NotAsked ->
                    Html.text ""

                Loading ->
                    -- thinking face
                    Html.text "\u{1F914}"

                Failure error ->
                    -- sad face
                    Html.text "😞"

                Success text ->
                    -- cowboy
                    Html.text "\u{1F920}"
            ]
        , Animator.Css.div timeline
            [ Animator.Css.explain debug
            , Animator.Css.opacity <|
                \state ->
                    case state of
                        Success _ ->
                            Animator.at 1

                        _ ->
                            Animator.at 0
            , Animator.Css.transformWith
                { rotationAxis =
                    { x = 0
                    , y = 0
                    , z = 1
                    }
                , origin =
                    Animator.Css.offset
                        -5
                        5
                }
              <|
                \state ->
                    case state of
                        NotAsked ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Loading ->
                            Animator.Css.rotating (Animator.seconds 5)

                        Failure error ->
                            Animator.Css.xy
                                { x = 0
                                , y = 0
                                }

                        Success text ->
                            fingerGuns 0
            ]
            []
            [ Html.div
                -- this is an adjustment to get this hand to point in the desired direction.
                [ Attr.style "transform" "translateY(3px) scaleX(-1) rotate(270deg)"
                ]
                [ Html.text "☝️" ]
            ]
        ]


fingerGuns : Float -> Animator.Css.Transform
fingerGuns offset =
    Animator.Css.in2d
        (Animator.Css.repeat 3 (Animator.millis 300))
        { x = Animator.Css.resting 0
        , y = Animator.Css.resting 0
        , rotate =
            Animator.zigzag (turns 0) (turns -0.1)
                |> Animator.shift offset
        , scaleX = Animator.Css.resting 1
        , scaleY = Animator.Css.resting 1
        }
