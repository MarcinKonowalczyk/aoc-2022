import os

if paramCount() != 1:
    echo "Usage: ./dayXX <input file>"
    quit(1)
let filename = paramStr(1)
if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)

## RUN: FULL
# RUN: TEST

import re
import strutils
import algorithm
import tables
import sequtils
import deques

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
var single_order: seq[string] = flow_rates_map.pairs.toSeq.filterIt(it[1] > 0).mapIt(it[0]).sorted()
assert single_order[0] != START

type
    Order = tuple[main: seq[string], extra: seq[string]]

var order = block:
    var result: Order
    for i, valve in single_order:
        if (i mod 2).bool:
            result.extra.add(valve)
        else:
            result.main.add(valve)
    result

func calc_flow_single(order: seq[string], flow_rates_map: Table[string, int], distance_map: Table[string, Table[string, int]]): int =
    var time = TIME_AVAILABLE
    for i in 0..<order.len:
        let
            prev = if i > 0: order[i - 1] else: START
            curr = order[i]
            distance = distance_map[prev][curr]

        time -= distance # Move to a valve
        if time < 0: break
        time -= 1 # Open a valve
        let add_flow = time * flow_rates_map[curr]
        result += add_flow
        if time < 0: break

        # debugecho "prev: ", prev, " curr: ", curr, " distance: ", distance, " time: ", time, " add_flow: ", add_flow

func calc_flow(order: Order, flow_rates_map: Table[string, int], distance_map: Table[string, Table[string, int]]): int =
    result = calc_flow_single(order.main, flow_rates_map, distance_map)
    result += calc_flow_single(order.extra, flow_rates_map, distance_map)

iterator candidates_single(order: seq[string]): seq[string] =
    # NOTE: I'm not sure this is guaranteed to always find the optimal solution
    #       but it's good enough for this problem. This is equivalent to
    #       2-steps-deep search for pairwis swaps.

    yield order

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

iterator candidates(order: Order): Order =
    # First yield from `candidates_single` for individual orders
    for main in candidates_single(order.main):
        for extra in candidates_single(order.extra):
            yield (main: main, extra: extra)
    
    # ....

    
proc find_next_candidate(order: var Order, max_flow: var int): bool = 
    for candidate in candidates(order):
        let flow = calc_flow(candidate, flow_rates_map, distance_map)
        if flow > max_flow:
            max_flow = flow
            order = candidate
            result = true
            echo "New max flow: ", max_flow, " order: ", order
            break

var max_flow = calc_flow(order, flow_rates_map, distance_map)
echo "Initial max flow: ", max_flow, " order: ", order
var swap_counter = 0
while find_next_candidate(order, max_flow):
    swap_counter += 1
    if swap_counter mod 100 == 0:
        echo "Swaps: ", swap_counter

echo max_flow