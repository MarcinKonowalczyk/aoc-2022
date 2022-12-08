import std/strutils
import std/sequtils

# let filename = "./data/test/day02_input.txt";
let filename = "./data/full/day02_input.txt";

type
    play = enum
        rock, paper, scissors
    result = enum
        loose, draw, win
    strategy = tuple
        play: play
        result: result

var games: seq[strategy]
for line in lines(filename):
    let parts = line.split(" ").map(proc (x: string): char = x[0]);
    var
        p: play
        r: result

    case parts[0]:
    of 'A': p = rock
    of 'B': p = paper
    of 'C': p = scissors
    else: raise newException(ValueError, "Invalid token: " & parts[0])

    case parts[1]:
    of 'X': r = loose
    of 'Y': r = draw
    of 'Z': r = win
    else: raise newException(ValueError, "Invalid token: " & parts[1])
    
    games.add((play: p, result: r))

proc calculate_play(x: play, y: result): play = 
    case y
    of win:
        case x
        of rock: paper
        of paper: scissors
        of scissors: rock
    of draw:
        x
    of loose:
        case x
        of rock: scissors
        of paper: rock
        of scissors: paper

proc calcualte_result(x,y: play): int =
    case x
    of rock:
        case y
        of rock: 3
        of paper: 6
        of scissors: 0
    of paper:
        case y
        of rock: 0
        of paper: 3
        of scissors: 6
    of scissors:
        case y
        of rock: 6
        of paper: 0
        of scissors: 3

let bonus: array[play, int] = [1,2,3]

var scores = seq[int](@[])
for game in games:
    let play = calculate_play(game.play, game.result)
    scores.add(calcualte_result(game.play, play) + bonus[play])
#     scores.add(result(game[0], game[1]) + bonus[game[1]])

echo scores.foldl(a + b)
