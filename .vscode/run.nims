#!/usr/bin/env nim
import std/os
import system/io
import std/strutils
import std/sequtils

echo "Hello from run script.nims ^_^"

let file = paramStr(3)
let file_parts = file.splitFile

type
    RunType = enum
        Test, Full

proc findRunType(filename: string): RunType =
    let lines = readFile(filename)
    for line in lines.split("\n"):
        if line != "" and line.len > 5 and line[0] == '#' and line[1] != '#':
            let split_line = line.split(" ").filterIt(it != "")
            if split_line[1] == "RUN:":
                assert(split_line.len == 3)
                case split_line[2]:
                of "TEST":
                    return Test
                of "FULL":
                    return Full
                else:
                    echo "Unknown run type: " & split_line[2]
                    quit(1)

if file_parts.name == "run" and file_parts.ext == ".nims":

    proc purple(s: string): string = "\e[0;34m" & s & "\e[0m"
    proc darkgray(s: string): string = "\e[1;30m" & s & "\e[0m"

    let lines: array[5, string] = [
        " ______   __  __   __   __         __   __   __   __    __   ______".purple,
        "/\\  == \\ /\\ \\/\\ \\ /\\ \"-.\\ \\       /\\ \"-.\\ \\ /\\ \\ /\\ \"-./  \\ /\\  ___\\".purple,
        "\\ \\  __< \\ \\ \\_\\ \\\\ \\ \\-.  \\   ".purple & "__".darkgray & " \\ \\ \\-.  \\\\ \\ \\\\ \\ \\-./\\ \\\\ \\___  \\".purple,
        " \\ \\_\\ \\_\\\\ \\_____\\\\ \\_\\\\\"\\_\\ ".purple & "/\\_\\".darkgray & " \\ \\_\\\\\"\\_\\\\ \\_\\\\ \\_\\ \\ \\_\\\\/\\_____\"".purple,
        "  \\/_/ /_/ \\/_____/ \\/_/ \\/_/ ".purple & "\\/_/".darkgray & "  \\/_/ \\/_/ \\/_/ \\/_/  \\/_/ \\/_____/".purple,
    ]

    for line in lines:
        echo line
    echo ""

elif file_parts.name == "build_all" and file_parts.ext == ".nims":
    selfExec(file)

elif file_parts.ext == ".nim" and file_parts.name[0..<3] == "day":
    

    let built_file = joinPath(file_parts.dir, "build", file_parts.name)
    if fileExists(built_file):
        rmFile(built_file)

    let cmd = "compile --outdir:build " & file
    # let cmd = "compile -d:release --opt:speed --passC:-flto --passL:-flto --outdir:build " & file
    echo cmd
    selfExec(cmd)

    let day = file_parts.name.split('_')[0]
    let data_dir = if findRunType(file) == RunType.Test: "test" else: "full"
    let input_file = joinPath(file_parts.dir, "data", data_dir, day & "_input.txt")
    if fileExists(built_file) and fileExists(input_file):
        echo "Running " & built_file
        exec(built_file & " " & input_file)
    else:
        echo "Built file or input file do not exist"
        quit(1)
else:
    echo "Unknown file type"
