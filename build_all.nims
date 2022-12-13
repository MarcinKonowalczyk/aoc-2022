mode = ScriptMode.Verbose

import os
import strutils
import sequtils

let root_dir = thisDir()

let files = listFiles(root_dir)
    .map(splitFile)
    .filterIt(it.ext == ".nim" and it.name.startsWith("day"))

let targets = files.mapIt(joinPath(it.dir, "build", it.name))

for (file, target) in zip(files, targets):
    if fileExists(target):
        exec("rm " & target)

    # let compile_command = "nim compile --verbosity:0 -o:" & target & " " & joinPath(root_dir, file.name & ".nim")
    let compile_command = "nim compile --verbosity:0 -d:release --opt:speed --passC:-flto --passL:-flto -o:" & target & " " & joinPath(root_dir, file.name & ".nim")
    exec(compile_command)

# Run all

let results_file = "results.txt"

if fileExists(results_file):
    exec("rm " & results_file)
    exec("touch " & results_file)

exec("echo \"script test full\" >> " & results_file)

for (file, target) in zip(files, targets):
    let day = file.name.split('_')[0]

    let test_input_file = joinPath(root_dir, "data", "test", day & "_input.txt")
    if not fileExists(test_input_file):
        echo "Input file" & test_input_file & " does not exist"
        quit(1)

    let full_input_file = joinPath(root_dir, "data", "full", day & "_input.txt")
    if not fileExists(full_input_file):
        echo "Input file" & full_input_file & " does not exist"
        quit(1)

    let test_command = "FULL_RESULT=$(rm -f temp.txt && " & target & " " & test_input_file & " >> temp.txt && tail -n 1 temp.txt && rm -f temp.txt)"
    let full_command = "TEST_RESULT=$(rm -f temp.txt && " & target & " " & full_input_file & " >> temp.txt && tail -n 1 temp.txt && rm -f temp.txt)"
    let command = test_command & " && " & full_command & " && echo \"" & file.name & " $FULL_RESULT $TEST_RESULT\" >> " & results_file
    exec(command)
    # exec("FULL_RESULT=$(" & target & " " & full_input_file & ") >> " & results_file & " 2>&1 && echo \"" & file_parts.name & ": $FULL_RESULT\" >> " & results_file)
