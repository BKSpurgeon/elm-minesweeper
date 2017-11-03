module Main exposing (..)

import Html exposing (Html, div, h1, p, pre, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onMouseDown, onMouseEnter, onMouseUp)


main : Program Never Model Msg
main =
    Html.program
        { init = ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type CellState
    = Pristine
    | Flagged
    | Pressed
    | Empty
    | Neighbor Int


type alias Cell =
    { x : Int
    , y : Int
    , state : CellState
    , bomb : Bool
    }


type alias Column =
    List Cell


type alias Grid =
    List Column


type alias Model =
    { grid : Grid
    , activeCell : Maybe Cell
    }


fromDimensions : Int -> Int -> Grid
fromDimensions width height =
    let
        makeColumn : Int -> Column
        makeColumn x =
            List.range 1 height
                |> List.map (\y -> Cell x y Pristine False)
    in
    List.range 1 width
        |> List.map makeColumn


withBombs : Int -> Grid -> Grid
withBombs count grid =
    let
        total =
            totalBombs grid

        cell =
            findEmptyCell grid
    in
    if total < count then
        withBombs
            count
            (updateCell
                (\cell -> { cell | bomb = True })
                cell
                grid
            )
    else
        grid


findEmptyCell : Grid -> Cell
findEmptyCell grid =
    let
        empties =
            gridToCells grid
                |> List.filter (\cell -> not cell.bomb)

        first =
            case List.head empties of
                Just empty ->
                    empty

                Nothing ->
                    Debug.crash ""
    in
    first


totalBombs : Grid -> Int
totalBombs grid =
    List.length <| List.filter .bomb (gridToCells grid)


gridToCells : Grid -> List Cell
gridToCells grid =
    List.concat grid


initialModel : Model
initialModel =
    { grid = withBombs 40 (fromDimensions 16 16)
    , activeCell = Nothing
    }


type Msg
    = MouseUpCell Cell
    | PressDown Cell


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ grid } as model) =
    case msg of
        MouseUpCell cell ->
            ( { model
                | grid =
                    updateCellState cell model.grid
                , activeCell = Nothing
              }
            , Cmd.none
            )

        PressDown cell ->
            ( { model | activeCell = Just cell }, Cmd.none )


updateCellState : Cell -> Grid -> Grid
updateCellState cell grid =
    let
        state =
            case cell.state of
                Pressed ->
                    Empty

                _ ->
                    cell.state
    in
    updateCell
        (\cell -> { cell | state = state })
        cell
        grid


updateCell : (Cell -> Cell) -> Cell -> Grid -> Grid
updateCell newCell cell grid =
    let
        replaceCell : Column -> Column
        replaceCell col =
            List.map
                (\og ->
                    if og.x == cell.x && og.y == cell.y then
                        newCell
                            cell
                    else
                        og
                )
                col
    in
    grid |> List.map replaceCell


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch []


view : Model -> Html Msg
view model =
    let
        background =
            styled div
                [ ( "box-sizing", "border-box" )
                , ( "min-height", "100vh" )
                , ( "width", "100%" )
                , ( "overflow", "hidden" )
                , ( "background-image", "url('https://www.hdwallpapers.in/walls/windows_xp_bliss-wide.jpg')" )
                ]

        frame =
            styled div
                [ ( "display", "inline-block" )
                , ( "background-color", "#bdbdbd" )
                , ( "padding", "5px" )
                , ( "border", "2px solid #7b7b7b" )
                , ( "border-top-color", "#fff" )
                , ( "border-left-color", "#fff" )
                ]
    in
    background
        []
        [ h1 [] [ text "~ minesweeper ~" ]
        , frame
            []
            [ insetDiv
                [ style
                    [ ( "height", "36px" )
                    , ( "margin-bottom", "5px" )
                    ]
                ]
                []
            , viewGrid model.activeCell model.grid
            ]
        ]


viewGrid : Maybe Cell -> Grid -> Html Msg
viewGrid activeCell grid =
    let
        size =
            16

        gridWidth =
            size * List.length grid

        columnHeight =
            case List.head grid of
                Just column ->
                    List.length column

                Nothing ->
                    0

        gridHeight =
            size * columnHeight

        markPressed : Cell -> Cell
        markPressed cell =
            case activeCell of
                Just active ->
                    if active == cell then
                        { cell | state = Pressed }
                    else
                        cell

                Nothing ->
                    cell

        hasPressed : Maybe Cell -> Bool
        hasPressed active =
            case active of
                Just cell ->
                    True

                Nothing ->
                    False

        viewColumn column =
            div
                [ style
                    [ ( "display", "inline-block" )
                    ]
                ]
                (column
                    |> List.map (markPressed >> viewCell size (hasPressed activeCell))
                )
    in
    insetDiv
        [ style
            [ ( "width", toString gridWidth ++ "px" )
            , ( "height", px gridHeight )
            ]
        ]
        (grid |> List.map viewColumn)


viewCell : Int -> Bool -> Cell -> Html Msg
viewCell size downOnHover cell =
    let
        upStyle =
            [ ( "border", "2px solid #fff" )
            , ( "border-bottom-color", "#7b7b7b" )
            , ( "border-right-color", "#7b7b7b" )
            ]

        downStyle =
            [ ( "border-left", "1px solid #838383" )
            , ( "border-top", "1px solid #838383" )
            ]

        makeCellDiv extension =
            styled div
                ([ ( "box-sizing", "border-box" )
                 , ( "width", px size )
                 , ( "height", px size )
                 , ( "font-size", "10px" )
                 , ( "text-align", "center" )
                 , ( "overflow", "hidden" )
                 ]
                    ++ extension
                )

        cellStyle =
            case cell.state of
                Pristine ->
                    upStyle

                Empty ->
                    downStyle

                Pressed ->
                    downStyle

                _ ->
                    []

        cellDiv =
            makeCellDiv cellStyle

        additionalEvents =
            if downOnHover then
                [ onMouseEnter (PressDown cell) ]
            else
                []
    in
    cellDiv
        ([ onMouseUp (MouseUpCell cell)
         , onMouseDown (PressDown cell)
         ]
            ++ additionalEvents
        )
        (if cell.bomb then
            [ text "*" ]
         else
            []
        )


px : Int -> String
px x =
    toString x ++ "px"


type alias Element msg =
    List (Html.Attribute msg) -> List (Html msg) -> Html msg


insetDiv : Element msg
insetDiv =
    styled div
        [ ( "border", "2px solid #7b7b7b" )
        , ( "border-bottom-color", "#fff" )
        , ( "border-right-color", "#fff" )
        ]


styled : Element msg -> List ( String, String ) -> Element msg
styled el css =
    \attrs children ->
        el ([ style css ] ++ attrs) children
