mode = ScriptMode.Verbose

import std/os
import std/strutils

let results_file = "results.txt"

if fileExists(results_file):
    exec("rm " & results_file)
    exec("touch " & results_file)

# var results = newSeq[string]()
for file in listFiles(thisDir()):
    let file_parts = splitFile(file)
    # Check if name starts with "day"
    if file_parts.ext == ".nim" and file_parts.name.startsWith("day"):
        let built_file = "build/" & file_parts.name
        if fileExists(built_file):
            exec("rm " & built_file)
        exec("nim compile --verbosity:0 -d:release --opt:speed --passC:-flto --passL:-flto -o:" & built_file & " " & file)
        exec("RESULT=$(" & built_file & ") >> " & results_file & " 2>&1 && echo \"" & file_parts.name & ": $RESULT\" >> " & results_file)
