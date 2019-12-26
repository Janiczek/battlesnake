port module Main exposing (main)

import Dict exposing (Dict)
import Dict.Extra


port startRequest : (GameState -> msg) -> Sub msg


port startResponse : StartData -> Cmd msg


port moveRequest : (GameState -> msg) -> Sub msg


port moveResponse : MoveData -> Cmd msg


port endRequest : (GameState -> msg) -> Sub msg


type Direction
    = Up
    | Down
    | Left
    | Right


type alias Coord =
    { x : Int
    , y : Int
    }


type alias Board =
    { height : Int
    , width : Int
    , food : List Coord
    , snakes : List Snake
    }


type alias Snake =
    { id : String
    , name : String
    , health : Int
    , body : List Coord
    }


type alias GameState =
    { game : { id : String }
    , turn : Int
    , board : Board
    , you : Snake
    }


type alias StartData =
    { color : String
    , headType : String
    , tailType : String
    }


type alias MoveData =
    { move : String }


type Model
    = NotPlaying
    | Playing GameState


type Msg
    = NoOp
    | Start GameState
    | Move GameState
    | End GameState


startData : StartData
startData =
    { color = "#DFFF00"
    , headType = "fang"
    , tailType = "hook"
    }


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init () =
    ( NotPlaying, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Start state ->
            start (print "start" state) model

        Move state ->
            move (print "move" state) model

        End state ->
            end (print "end" state) model


start : GameState -> Model -> ( Model, Cmd Msg )
start state model =
    ( Playing state
    , startResponse startData
    )


move : GameState -> Model -> ( Model, Cmd Msg )
move state model =
    ( Playing state
    , moveResponse <| toMoveData Up
    )


end : GameState -> Model -> ( Model, Cmd Msg )
end state model =
    ( NotPlaying
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ startRequest Start
        , moveRequest Move
        , endRequest End
        ]


toMoveData : Direction -> MoveData
toMoveData direction =
    { move =
        case direction of
            Up ->
                "up"

            Down ->
                "down"

            Left ->
                "left"

            Right ->
                "right"
    }


print : String -> GameState -> GameState
print label state =
    let
        realLabel =
            label
                ++ ", turn "
                ++ String.fromInt state.turn

        string =
            state.board
                |> boardToDict
                |> dictToString

        _ =
            Debug.log ("\n" ++ string ++ "\n") realLabel
    in
    state


boardToDict : Board -> Dict ( Int, Int ) Char
boardToDict board =
    let
        emptyDict =
            List.range 0 (board.height - 1)
                |> List.concatMap
                    (\y ->
                        List.range 0 (board.width - 1)
                            |> List.map (\x -> ( ( x, y ), '.' ))
                    )
                |> Dict.fromList

        objects =
            (List.map (\c -> ( c, '#' )) board.food
                :: List.indexedMap
                    (\i { body } -> List.map (\c -> ( c, Char.fromCode (i + 48) )) body)
                    board.snakes
            )
                |> List.concat
                |> List.map (Tuple.mapFirst coordToTuple)
    in
    List.foldl
        (\( coord, char ) -> Dict.insert coord char)
        emptyDict
        objects


dictToString : Dict ( Int, Int ) Char -> String
dictToString dict =
    dict
        |> Dict.toList
        -- group by y
        |> Dict.Extra.groupBy (Tuple.first >> Tuple.second)
        |> Dict.toList
        -- sort by y
        |> List.sortBy Tuple.first
        -- rows to strings
        |> List.map
            (\( y, cells ) ->
                cells
                    -- sort by x
                    |> List.sortBy (Tuple.first >> Tuple.first)
                    -- get the char
                    |> List.map Tuple.second
                    |> String.fromList
            )
        |> String.join "\n"


swapTuple : ( Int, Int ) -> ( Int, Int )
swapTuple ( x, y ) =
    ( y, x )


coordToTuple : Coord -> ( Int, Int )
coordToTuple { x, y } =
    ( x, y )
