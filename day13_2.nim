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
import algorithm

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

var packets: seq[Packet] = @[]

let file: File = open(filename, fmRead)

try:
    while not endOfFile(file):
        var line = readLine(file)
        if line.len == 0:
            continue
        packets.add(line.toPacket)

finally:
    file.close()

func sign(a, b: int): int =
    if a < b:
        return -1
    elif a > b:
        return 1
    else:
        return 0

func `<?`(a, b: Packet): int =
    case a.kind
    of pkInt:
        case b.kind
        of pkInt:
            return sign(b.intVal, a.intVal)
        of pkSeq:
            return newPacket(@[a]) <? b
    of pkSeq:
        case b.kind
        of pkInt:
            return a <? newPacket(@[b])
        of pkSeq:
            for i in 0..<max(a.len, b.len):
                if i > a.len-1:
                    return 1
                if i > b.len-1:
                    return -1
                let s = a[i] <? b[i]
                if s != 0:
                    return s
            return 0

func `<`(p1, p2: Packet): bool = 
    let r = p1 <? p2
    assert(r != 0)
    return r == 1

let
    divider_1 = "[[2]]".toPacket
    divider_2 = "[[6]]".toPacket
packets.add(divider_1)
packets.add(divider_2)
packets.sort()

var
    divider_2_index = -1
    divider_1_index = -1

for i, p in packets:
    echo p
    if p == divider_1:
        assert(divider_1_index == -1)
        divider_1_index = i+1
    elif p == divider_2:
        assert(divider_2_index == -1)
        divider_2_index = i+1

echo divider_1_index * divider_2_index