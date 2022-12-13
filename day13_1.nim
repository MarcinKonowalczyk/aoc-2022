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

import sequtils
import strutils
# import deques

type
    PacketKind = enum
        pkInt, pkSeq
  
    Packet = ref object
        case kind: PacketKind  # the ``kind`` field is the discriminator
        of pkInt:
            intVal: int
        of pkSeq:
            seqVal: seq[Packet]

func len(p: Packet): int =
    case p.kind
    of pkInt:
        return 1
    of pkSeq:
        return p.seqVal.len

func `[]`(p: Packet, i: int): Packet =
    case p.kind
    of pkInt:
        return p
    of pkSeq:
        return p.seqVal[i]

proc echo(p: Packet, level: int = 0) =
    case p.kind
    of pkInt:
        write(stdout, p.intVal)
    of pkSeq:
        write(stdout, "[")
        let N = p.seqVal.len
        for i, p in p.seqVal:
            echo(p, level+1)
            if i < N-1:
                write(stdout, ",")
        write(stdout, "]")
    if level == 0:
        write(stdout, "\n")

func newPacket(intVal: int): Packet =
    result = Packet(kind: pkInt, intVal: intVal)

func newPacket(seqVal: seq[Packet]): Packet =
    result = Packet(kind: pkSeq, seqVal: seqVal)

func newPacket(seqVal: seq[int]): Packet =
    result = Packet(kind: pkSeq, seqVal: seqVal.map(newPacket))

func toPacket(s: string): Packet =
    if s[0] == '[' and s[^1] == ']':
        # Parse top-level bracket
        var
            bracket_level = 0
            last_parsed = 0
            parts: seq[string]
        for i in countup(1, len(s)-2):
            if s[i] == '[':
                bracket_level += 1
            elif s[i] == ']':
                bracket_level -= 1
            elif s[i] == ',' and bracket_level == 0:
                parts.add(s[last_parsed+1..i-1])
                last_parsed = i
        parts.add(s[last_parsed+1..^2]) # Add last part
        return newPacket(parts.filterIt(it.len > 0).mapIt(it.toPacket))
    else:
        # Parse int
        return newPacket(s.parseInt)

var packets: seq[tuple[a, b: Packet]] = @[]

let file: File = open(filename, fmRead)

try:
    while not endOfFile(file):
        var line1 = ""
        while line1.len == 0: line1 = readLine(file)
        var line2 = ""
        while line2.len == 0: line2 = readLine(file)
        packets.add((line1.toPacket, line2.toPacket))

finally:
    file.close()

func sign(a, b: int): int =
    if a < b:
        return -1
    elif a > b:
        return 1
    else:
        return 0

func `<`(a, b: Packet): int =
    case a.kind
    of pkInt:
        case b.kind
        of pkInt:
            return sign(b.intVal, a.intVal)
        of pkSeq:
            return newPacket(@[a]) < b
    of pkSeq:
        case b.kind
        of pkInt:
            return a < newPacket(@[b])
        of pkSeq:
            for i in 0..<max(a.len, b.len):
                if i > a.len-1:
                    return 1
                if i > b.len-1:
                    return -1
                let s = a[i] < b[i]
                if s != 0:
                    return s
            return 0

var comps: seq[tuple[index: int, result: bool]] = @[]

for i, (p1, p2) in packets.pairs:
    let r = p1 < p2
    assert r != 0
    comps.add((i+1, r == 1))

echo comps.filterIt(it.result).foldl(a + b.index, 0)
