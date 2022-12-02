#!/usr/bin/env nim
import std/os
import system/io

echo "Hello from run script.nims ^_^"

let file = paramStr(3)
let file_parts = file.splitFile

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

elif file_parts.ext == ".nim":
    let built_file = "build/" & file_parts.name
    if fileExists(built_file):
        rmFile(built_file)

    let cmd = "compile --outdir:build " & file
    echo cmd
    selfExec(cmd)
    if fileExists(built_file):
        echo "Running " & built_file
        exec(built_file)
else:
    echo "Unknown file type"
