import os

if paramCount() != 1:
    echo "Usage: ./dayXX <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

# RUN: FULL
## RUN: TEST

import strutils
import sequtils
import algorithm

const
    UINT_MAX = uint.high
    UINT_MIN = uint.low

##========================================
##                                        
##  #####    ####  ####  ##   ##  ######
##  ##  ##  ##  ##  ##   ###  ##    ##  
##  #####   ##  ##  ##   #### ##    ##  
##  ##      ##  ##  ##   ## ####    ##  
##  ##       ####  ####  ##  ###    ##  
##                                        
##========================================

type
    Point = tuple
        x, y: uint

func newPoint(x, y: uint): Point {.inline.} =
    result = (x, y)

func newPoint(x, y: SomeInteger): Point {.inline.} =
    assert x >= 0 and y >= 0
    # assert x <= uint.high and y <= uint.high
    result = (uint(x), uint(y))

func newPoint(p: Point): Point {.inline.} =
    newPoint(p.x, p.y)

func `-`(a, b: Point): Point {.inline.} =
    assert b.x <= a.x and b.y <= a.y
    (a.x - b.x, a.y - b.y)

func `-=`(a: var Point, b: Point) {.inline.} =
    a = a - b

func `+`(a, b: Point): Point {.inline.} =
    (a.x + b.x, a.y + b.y)

func `+=`(a: var Point, b: Point) {.inline.} =
    a = a + b

##=================================
##                                 
##  ##      ####  ##   ##  ######
##  ##       ##   ###  ##  ##    
##  ##       ##   #### ##  ##### 
##  ##       ##   ## ####  ##    
##  ######  ####  ##  ###  ######
##                                 
##=================================

type
    LineKind = enum
        lkHorizontal, lkVertical, lkInfiniteHorizontal

    Line = object
        case kind: LineKind
        of lkHorizontal:
            x1, x2, y: uint
        of lkVertical:
            x, y1, y2: uint
        of lkInfiniteHorizontal:
            iy: uint

func newHLine(x1, x2, y: uint): Line {.inline.} =
    Line(kind: lkHorizontal, x1: x1, x2: x2, y: y)

func newVLine(x, y1, y2: uint): Line {.inline.} =
    Line(kind: lkVertical, x: x, y1: y1, y2: y2)

func newIHLine(y: uint): Line {.inline.} =
    Line(kind: lkInfiniteHorizontal, iy: y)

func newLine(p1, p2: Point): Line {.inline.} = 
    if p1.x == p2.x:
        assert p1.y != p2.y
        result = newVLine(p1.x, p1.y, p2.y)
    elif p1.y == p2.y:
        assert p1.x != p2.x
        result = newHLine(p1.x, p2.x, p1.y)
    else:
        raise newException(ValueError, "Invalid points. Must be on the same grid-aligned) line.")

func `+`(a: Line, b: Point): Line {.inline.} = 
    case a.kind
    of lkHorizontal:
        newHLine(a.x1 + b.x, a.x2 + b.x, a.y + b.y)
    of lkVertical:
        newVLine(a.x + b.x, a.y1 + b.y, a.y2 + b.y)
    of lkInfiniteHorizontal:
        newIHLine(a.iy + b.y)

func `-`(a: Line, b: Point): Line {.inline.} = 
    case a.kind
    of lkHorizontal:
        newHLine(a.x1 - b.x, a.x2 - b.x, a.y - b.y)
    of lkVertical:
        newVLine(a.x - b.x, a.y1 - b.y, a.y2 - b.y)
    of lkInfiniteHorizontal:
        newIHLine(a.iy - b.y)

func `+=`(a: var Line, b: Point) {.inline.} =
    a = a + b

func `-=`(a: var Line, b: Point) {.inline.} =
    a = a - b

func `[]`(l: Line, i: uint): Point =
    case l.kind
    of lkHorizontal:
        case i
        of 0: (l.x1, l.y)
        of 1: (l.x2, l.y)
        else: raise newException(IndexDefect, "Invalid index: " & $i)
    of lkVertical:
        case i
        of 0: (l.x, l.y1)
        of 1: (l.x, l.y2)
        else: raise newException(IndexDefect, "Invalid index: " & $i)
    of lkInfiniteHorizontal:
        case i
        of 0: (UINT_MIN, l.iy)
        of 1: (UINT_MAX, l.iy)
        else: raise newException(IndexDefect, "Invalid index: " & $i)

proc echo(l: Line, newline: bool = true) =
    case l.kind
    of lkHorizontal:
        write(stdout, "H(x:[", l.x1, ",", l.x2, "],y:", l.y, ")")
    of lkVertical:
        write(stdout, "V(x:", l.x, ",y:[", l.y1, ",", l.y2, "])")
    of lkInfiniteHorizontal:
        write(stdout, "IH(y:", l.iy, ")")
    if newline:
        write(stdout, "\n")

##================================================
##                                                
##   ####  #####   ##      ####  ##   ##  ######
##  ##     ##  ##  ##       ##   ###  ##  ##    
##   ###   #####   ##       ##   #### ##  ##### 
##     ##  ##      ##       ##   ## ####  ##    
##  ####   ##      ######  ####  ##  ###  ######
##                                                
##================================================

type
    Spline = object
        lines: seq[Line]
        start: Point
        start_set: bool

func newSpline(): Spline =
    Spline(lines: @[], start: newPoint(0, 0), start_set: false)

func newSpline(p: Point): Spline =
    Spline(lines: @[], start: p, start_set: true)

func newSpline(l: Line): Spline =
    Spline(lines: @[l], start: l[0], start_set: true)

proc add(s: var Spline, l: Line) =
    let lp = if s.lines.len > 0:
        s.lines[^1][1]
    else:
        s.start
    if lp != l[0]:
        raise newException(ValueError, "Invalid line. Must start at the end of the last line.")
    s.lines.add(l)

proc add(s: var Spline, p: Point) =
    if not s.start_set:
        s.start = p
        s.start_set = true
    else:
        let lp = if s.lines.len > 0:
            s.lines[^1][1]
        else:
            s.start

        if lp.x == p.x:
            assert lp.y != p.y
            s.add(newLine(lp, p))
        elif lp.y == p.y:
            assert lp.x != p.x
            s.add(newLine(lp, p))
        else:
            raise newException(ValueError, "Invalid point. Must be on the same grid-aligned line as the last line.")

func `-`(s: Spline, b: Point): Spline =
    result = newSpline(s.start - b)
    for line in s.lines:
        result.add(line - b)

func newSpline(l: seq[Line]): Spline =
    result = newSpline()
    for line in l:
        result.add(line)

proc echo(s: Spline, newline: bool = true) =
    write(stdout, "[ ")
    let N = s.lines.len
    for i, line in s.lines:
        echo(line, newline=false)
        if i < N-1:
            write(stdout, ", ")
    write(stdout, " ]")
    if newline:
        write(stdout, "\n")

func `[]`(s: Spline, i: int): Line {.inline.} =
    s.lines[i]

##==================================
##                                  
##   ####  #####    ###    ##   ##
##  ##     ##  ##  ## ##   ###  ##
##   ###   #####  ##   ##  #### ##
##     ##  ##     #######  ## ####
##  ####   ##     ##   ##  ##  ###
##                                  
##==================================

type
    Span = tuple
        x1, x2, y1, y2: uint

func span(l: Line): Span {.inline.} =
    case l.kind
    of lkHorizontal:
        (min(l.x1, l.x2), max(l.x1, l.x2), l.y, l.y)
    of lkVertical:
        (l.x, l.x, min(l.y1, l.y2), max(l.y1, l.y2))
    of lkInfiniteHorizontal:
        (UINT_MIN, UINT_MAX, l.iy, l.iy)

func span(p: Point): Span {.inline.} =
    (p.x, p.x, p.y, p.y)

const MIN_SPAN: Span = (UINT_MAX, UINT_MIN, UINT_MAX, UINT_MIN)

func `+`(a, b: Span): Span {.inline.} =
    (min(a.x1, b.x1), max(a.x2, b.x2), min(a.y1, b.y1), max(a.y2, b.y2))

func `+=`(a: var Span, b: Span) {.inline.} =
    a = a + b

func `-`(a: Span, b: Point): Span {.inline.} =
    (a.x1 - b.x, a.x2 - b.x, a.y1 - b.y, a.y2 - b.y)

func `-=`(a: var Span, b: Point) {.inline.} =
    a = a - b

func width(s: Span): int {.inline.} =
    int(s.x2 - s.x1 + 1)

func height(s: Span): int {.inline.} =
    int(s.y2 - s.y1 + 1)

func `[]`(s: Span, x, y: int): Point {.inline.} =
    assert x >= 0 and y >= 0
    (s.x1 + uint(x), s.y1 + uint(y))

func span(s: Spline): Span {.inline.} = 
    result = MIN_SPAN
    for l in s.lines:
        result += l.span

proc span(ss: seq[Spline]): Span {.inline.} =
    result = MIN_SPAN
    for s in ss:
        result += s.span

proc span(sp: seq[Point]): Span {.inline.} =
    result = MIN_SPAN
    for p in sp:
        result += p.span

##===============================
##                               
##  #####  ####  ##      ######
##  ##  ##  ##   ##      ##    
##  #####   ##   ##      ##### 
##  ##      ##   ##      ##    
##  ##     ####  ######  ######
##                               
##===============================

type
    Rock = object
        point: Point
        hat: int
    Pile = object
        top: seq[Rock]
        covered: seq[Rock]

func newRock(p: Point, n: int = 0): Rock =
    Rock(point: p, hat: n)

func newRock(x, y: uint, n: int = 0): Rock =
    newRock((x, y), n)

func span(pl: Pile): Span =
    result = MIN_SPAN
    for r in pl.top:
        result += r.point.span

##=============================================================
##                                                             
##   ####   ##   ##  ######  #####    ##        ###    ##### 
##  ##  ##  ##   ##  ##      ##  ##   ##       ## ##   ##  ##
##  ##  ##  ##   ##  #####   #####    ##      ##   ##  ##### 
##  ##  ##   ## ##   ##      ##  ##   ##      #######  ##    
##   ####     ###    ######  ##   ##  ######  ##   ##  ##    
##                                                             
##=============================================================

func `^`(p1, p2: Point): bool {.inline.} = 
    p1.x == p2.x and p1.y == p2.y

func `^`(p: Point, s: seq[Point]): bool {.inline.} =
    for p2 in s:
        if p ^ p2:
            return true
    return false

func `^`(s: seq[Point], p: Point): bool {.inline.} =
    p ^ s

func `^`(l: Line, p: Point): bool {.inline.} =
    let sl = l.span
    return p.x >= sl.x1 and p.x <= sl.x2 and p.y >= sl.y1 and p.y <= sl.y2

func `^`(p: Point, l: Line): bool {.inline.} =
    l ^ p

func `^`(s: Spline, p: Point): bool {.inline.} =
    for l in s.lines:
        if l ^ p:
            return true
    return false

func `^`(p: Point, s: Spline): bool {.inline.} =
    s ^ p

func `^`(p: Point, ss: seq[Spline]): bool {.inline.} =
    for s in ss:
        if s ^ p:
            return true
    return false

func `^`(ss: seq[Spline], p: Point): bool {.inline.} =
    p ^ ss

func `^`(p: Point, pl: Pile): bool {.inline.} =
    for r in pl.top:
        if r.point ^ p:
            return true
    return false

func `^`(pl: Pile, p: Point): bool {.inline.} =
    p ^ pl

func `^`(r: Rock, pl: Pile): bool {.inline.} =
    for r2 in pl.top:
        if r.point ^ r2.point:
            return true
    return false

func `^`(pl: Pile, r: Rock): bool {.inline.} =
    r ^ pl

func `^`(r: Rock, p: Point): bool {.inline.} =
    r.point ^ p

func `^`(p: Point, r: Rock): bool {.inline.} =
    r ^ p

func `^`(sr: seq[Rock], p: Point): bool {.inline.} =
    for r in sr:
        if r ^ p:
            return true
    return false

func `^`(p: Point, sr: seq[Rock]): bool {.inline.} =
    sr ^ p

##====================================
##                                    
##  ##    ##    ###    ####  ##   ##
##  ###  ###   ## ##    ##   ###  ##
##  ## ## ##  ##   ##   ##   #### ##
##  ##    ##  #######   ##   ## ####
##  ##    ##  ##   ##  ####  ##  ###
##                                    
##====================================

var walls: seq[Spline]
block:
    for line in lines(filename):
        let split_line = line.split(" -> ")
        var s = newSpline()
        for coord in split_line:
            let split_coord = coord.split(",")
            let x = split_coord[0].parseUInt()
            let y = split_coord[1].parseUInt()
            s.add((x, y))
        walls.add(s)

let floor = newSpline(newIHLine(walls.span.y2 + 2))

walls.add(floor)

const start_point = newPoint(500, 0)

let sspan = walls.span
assert sspan.x1 <= start_point.x and sspan.x2 >= start_point.x
assert sspan.y2 >= start_point.y

type
    Move = enum
        none, down, left, right

proc nextMove(r:Rock, ss: seq[Spline], s: Pile): Move = 
    var next: Point = newPoint(r.point.x, r.point.y + 1)
    if not (next ^ ss or next ^ s):
        return down
    next = newPoint(r.point.x - 1, r.point.y + 1)
    if not (next ^ ss or next ^ s):
        return left
    next = newPoint(r.point.x + 1, r.point.y + 1)
    if not (next ^ ss or next ^ s):
        return right

proc draw(ss: seq[Spline], s: Pile) =

    let span = block:
        let not_floor = ss.filterIt(it.lines.len != 1 or it.lines[0].kind != lkInfiniteHorizontal)
        var temp = not_floor.span
        temp += s.span
        temp += start_point.span
        temp += newPoint(temp.x1, floor.span.y1).span
        temp

    var out_string = ""
    for y in 0 ..< span.height:
        for x in 0 ..< span.width:
            if ss ^ span[x, y]:
                out_string.add('#')
            elif s.top ^ span[x, y]:
                out_string.add('o')
            elif s.covered ^ span[x, y]:
                out_string.add('c')
            elif start_point ^ span[x, y]:
                out_string.add('+')
            else:
                out_string.add('.')
        out_string.add('\n')
    write(stdout, out_string)

var sand: Pile

const DEBUG: bool = false
const HAT_CAPACITY = 3

var sand_counter: int = 0
while true:
    var rock = newRock(start_point, n=0)
    if rock ^ sand:
        break
    while rock.point.y < (sspan.y2 + 1):
        let move = nextMove(rock, walls, sand)
        case move
        of down:
            rock.point.y += 1
        of left:
            rock.point.x -= 1
            rock.point.y += 1
        of right:
            rock.point.x += 1
            rock.point.y += 1
        of none:
            break

    if rock.point.y < (sspan.y2 + 1):
        # Add self as a hat for other rocks in the pile
        let
            down_left = newPoint(rock.point.x - 1, rock.point.y + 1)
            down_right = newPoint(rock.point.x + 1, rock.point.y + 1)
            down = newPoint(rock.point.x, rock.point.y + 1)

        var to_cover: seq[int] = @[]
        for i, s in sand.top.mpairs:
            for n in [down_left, down_right, down]:
                if s ^ n:
                    s.hat += 1
                    if s.hat == HAT_CAPACITY:
                        to_cover.add(i)

        for i in to_cover.reversed():
            sand.covered.add(sand.top[i])
            sand.top.del(i)
        
        # Also make add walls to the hat cover
        let
            top_right = newPoint(rock.point.x + 1, rock.point.y - 1)
            top_left = newPoint(rock.point.x - 1, rock.point.y - 1)
        
        for n in [top_right, top_left]:
            if n ^ walls:
                rock.hat += 1

        sand.top.add(rock)
    else:
        break

    if sand_counter  mod 100 == 0:
        echo "iteration: ", sand_counter, " len(sand.top) = ", sand.top.len, " len(sand.covered) = ", sand.covered.len

    sand_counter += 1

    if DEBUG: draw(walls, sand)
    if DEBUG:
        echo "len(sand.top) = ", sand.top.len
        echo "len(sand.covered) = ", sand.covered.len
    if DEBUG: sleep(500)

# draw(walls, sand)

echo len(sand.top) + len(sand.covered)