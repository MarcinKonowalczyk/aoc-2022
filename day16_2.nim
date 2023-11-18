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

import re
import strutils
import algorithm
import tables
import sequtils
import strformat
import deques
import std/enumerate

var data: seq[tuple[valve: string, flow: int, tunnels: seq[string]]]

for line in lines(filename):
    var matches: array[3, string]
    if not match(line, re"Valve ([A-Z]{2}) has flow rate=(\d+); tunnels? leads? to valves? (.*)", matches):
        echo "Invalid line: ", line
        quit(1)
    data.add((
        valve: matches[0],
        flow: parseInt(matches[1]),
        tunnels: matches[2].split(", ")
    ))

const
    START = "AA"
    TIME_AVAILABLE = 26
    # TIME_AVAILABLE = 30

block:
    var start = data.filterIt(it.valve == START)
    assert start.len == 1
    assert start[0].flow == 0


let flow_rates_map = block:
    var result: Table[string, int]
    for d in data:
        result[d.valve] = d.flow
    result


let tunnels_map = block:
    var result: Table[string, seq[string]]
    for d in data:
        result[d.valve] = d.tunnels
    result

func calc_distaces(tunnels_map: Table[string, seq[string]], start: string): Table[string, int] =
    assert start in tunnels_map
    result[start] = 0
    var to_visit: Deque[tuple[valve: string, distance: int]]
    for tunnel in tunnels_map[start]:
        to_visit.addLast((valve: tunnel, distance: 1))
    while to_visit.len > 0:
        let (valve, distance) = to_visit.popFirst()
        if valve notin result:
            result[valve] = distance
            for tunnel in tunnels_map[valve]:
                to_visit.addLast((valve: tunnel, distance: distance + 1))

let distance_map = block:
    var result: Table[string, Table[string, int]]
    for valve in tunnels_map.keys:
        result[valve] = calc_distaces(tunnels_map, valve)
    result

# Inital order
var order: seq[string] = flow_rates_map.pairs.toSeq.filterIt(it[1] > 0).mapIt(it[0]).sorted()
assert order[0] != START

# iterator two_partition(values: seq[string]): (seq[string], seq[string]) =
    # yield (@[], @[])

proc two_partition(values: seq[string], depth: int = 0): iterator: (seq[string], seq[string]) =
    result = iterator: (seq[string], seq[string]) {.closure.} =
        assert values.len > 1

        if values.len == 2:
            yield (values[0..0], values[1..1])
        else:
            let element = values[0..0]
            let other_elements = values[1..values.len-1]
            yield (element, other_elements)
            for (p1, p2) in two_partition(other_elements, depth = depth + 1):
                yield (concat(element, p1), p2)
                yield (concat(element, p2), p1)

func calc_flow(order: seq[string], flow_rates_map: Table[string, int], distance_map: Table[string, Table[string, int]]): int =
    var time = TIME_AVAILABLE
    for i in 0..<order.len:
        let
            prev = if i > 0: order[i - 1] else: START
            curr = order[i]
            distance = distance_map[prev][curr]

        time -= distance # Move to a vale
        if time < 0: break
        time -= 1 # Open a valve
        let add_flow = time * flow_rates_map[curr]
        result += add_flow
        if time < 0: break

        # debugecho "prev: ", prev, " curr: ", curr, " distance: ", distance, " time: ", time, " add_flow: ", add_flow


iterator candidates(order: seq[string]): seq[string] =
    # NOTE: I'm not sure this is guaranteed to always find the optimal solution
    #       but it's good enough for this problem. This is equivalent to
    #       2-steps-deep search for pairwis swaps.

    # Permute elements pairwise
    for i in 0..<order.len:
        for j in i + 1..<order.len:
            var new_order = order
            swap(new_order[i], new_order[j])
            yield new_order

            # For each permutation, permute elements pairwise again
            for k in 0..<new_order.len:
                for l in k + 1..<new_order.len:
                    var new_order2 = new_order
                    swap(new_order2[k], new_order2[l])
                    yield new_order2

# echo order
# for candidate in candidates(order):
#     echo candidate

# quit(1)

proc find_next_candidate(order: var seq[string], max_flow: var int, verbose: bool = true): bool = 
    for candidate in candidates(order):
        let flow = calc_flow(candidate, flow_rates_map, distance_map)
        if flow > max_flow:
            max_flow = flow
            order = candidate
            result = true
            if verbose:
                echo "New max flow: ", max_flow, " order: ", order
            break

proc optimize_flow(order: seq[string], verbose: bool = true): int =
    var order_copy = order;
    var max_flow = calc_flow(order, flow_rates_map, distance_map)
    if verbose:
        echo "Initial max flow: ", max_flow, " order: ", order
    var swap_counter = 0
    while find_next_candidate(order_copy, max_flow, verbose = verbose):
        swap_counter += 1
        if verbose and swap_counter mod 100 == 0:
            echo "Swaps: ", swap_counter
    result = max_flow


proc count_partitions(values: seq[string]): int =
    for _ in two_partition(order):
        result += 1


proc optimize_flow_across_partitions(order: seq[string]): int = 
    let N_partitions = count_partitions(order);
    for i, (p1, p2) in enumerate(two_partition(order)):
        if i mod 100 == 0:
            echo fmt"{i+1}/{N_partitions} ({(i+1)/N_partitions*100:.3f})%";
        let max_flow_p1 = optimize_flow(p1, verbose=false);
        let max_flow_p2 = optimize_flow(p2, verbose=false);
        let max_flow = max_flow_p1 + max_flow_p2;
        if max_flow > result:
            echo "New max flow: ", max_flow, " for p1: ", p1, ", p2: ", p2
            result = max_flow;

let max_flow = optimize_flow_across_partitions(order);
echo max_flow