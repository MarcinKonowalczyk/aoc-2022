import std/strutils
import std/sequtils
import std/sets

# let filename = "./data/test/day09_input.txt";
let filename = "./data/full/day09_input.txt";

type
    Direction = enum
        up, down, left, right

var path: seq[Direction] = @[]

for line in lines(filename):
    if line == "": continue
    if line[0] == '#': continue
    let split_line = line.split(" ")
    assert(split_line.len == 2)
    var direction: Direction
    case split_line[0]:
        of "U": direction = up
        of "D": direction = down
        of "L": direction = left
        of "R": direction = right
        else: assert(false)
    let distance = split_line[1].parseInt
    assert(distance > 0)
    for i in 0..<distance:
        path.add(direction)

type
    Point = tuple[x, y: int]

proc sign(x: int): int =
    if x > 0:
        return 1
    elif x < 0:
        return -1
    else:
        return 0
    
proc updateLink(head: Point, link: var Point) =
    let
        dx = head.x - link.x
        dy = head.y - link.y
    
    if dx.abs > 1 or dy.abs > 1:
        if dx.abs == dy.abs:
            link.x += dx.sign * (dx.abs - 1)
            link.y += dy.sign * (dy.abs - 1)
        elif dx.abs > dy.abs:
            link.y += dy.sign
            link.x += dx.sign * (dx.abs - 1)
        else:
            link.x += dx
            link.y += dy.sign * (dy.abs - 1)

proc updateAllLinks(head: Point, links: var seq[Point]) =
    for i in countup(0, links.len - 1):
        var link = links[i]
        if i == 0:
            updateLink(head, link)
        else:
            updateLink(links[i - 1], link)
        links[i] = link

proc purple(s: string): string = "\e[0;34m" & s & "\e[0m"
proc darkgray(s: string): string = "\e[0;30m" & s & "\e[0m"
proc green(s: string): string = "\e[1;32m" & s & "\e[0m"
proc red(s: string): string = "\e[0;31m" & s & "\e[0m"

proc printPositions(head: Point, links: seq[Point], start: Point = Point((x: 0, y: 0))) =
    let
        links_x_max = links.mapIt(it.x).max
        links_x_min = links.mapIt(it.x).min
        links_y_max = links.mapIt(it.y).max
        links_y_min = links.mapIt(it.y).min
        x_max = [head.x, links_x_max, start.x].max
        x_min = [head.x, links_x_min, start.x].min
        y_max = [head.y, links_y_max, start.y].max
        y_min = [head.y, links_y_min, start.y].min
    
    for y in countdown(y_max, y_min):
        for x in countup(x_min, x_max):
            if x == head.x and y == head.y:
                stdout.write("H".green)
            else:
                var found = false
                for i, link in links:
                    if x == link.x and y == link.y:
                        stdout.write(($(i + 1)).red)
                        found = true
                        break
                if not found:
                    if x == start.x and y == start.y:
                        stdout.write("s".purple)
                    else:
                        stdout.write(".".darkgray)
        stdout.write("\n")

var head = Point((x: 0, y: 0))

const N_LINKS = 9

var links = newSeq[Point](N_LINKS)
for i in 0..<N_LINKS:
    links[i] = Point((x: 0, y: 0))

var visited: HashSet[Point] = initHashSet[Point]()
visited.incl(links[^1])

const PRINT = false
# const PRINT = true

if PRINT:
    printPositions(head, links)
    echo ""

for step in path:
    case step:
        of up: head.y += 1
        of down: head.y -= 1
        of left: head.x -= 1
        of right: head.x += 1
    updateAllLinks(head, links)
    visited.incl(links[^1])
    if PRINT:
        printPositions(head, links)
        echo ""

# printPositions(head, links)

echo visited.len
    