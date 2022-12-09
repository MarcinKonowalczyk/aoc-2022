mode = ScriptMode.Verbose

import std/os
import std/strutils

let results_file = "results.txt"

if fileExists(results_file):
    exec("rm " & results_file)
    exec("touch " & results_file)

exec("echo \"script test full\" >> " & results_file)

# var results = newSeq[string]()
for file in listFiles(thisDir()):
    let file_parts = splitFile(file)
    # Check if name starts with "day"
    if file_parts.ext == ".nim" and file_parts.name.startsWith("day"):
        let built_file = joinPath("build", file_parts.name)
        if fileExists(built_file):
            exec("rm " & built_file)

        # let compile_command = "nim compile --verbosity:0 -o:" & built_file & " " & file
        let compile_command = "nim compile --verbosity:0 -d:release --opt:speed --passC:-flto --passL:-flto -o:" & built_file & " " & file
        exec(compile_command)

        let day = file_parts.name.split('_')[0]

        let test_input_file = joinPath(file_parts.dir, "data", "test", day & "_input.txt")
        if not fileExists(test_input_file):
            echo "Input file" & test_input_file & " does not exist"
            quit(1)

        let full_input_file = joinPath(file_parts.dir, "data", "full", day & "_input.txt")
        if not fileExists(full_input_file):
            echo "Input file" & full_input_file & " does not exist"
            quit(1)

        let test_command = "FULL_RESULT=$(rm -f temp.txt && " & built_file & " " & test_input_file & " >> temp.txt && tail -n 1 temp.txt && rm -f temp.txt)"
        let full_command = "TEST_RESULT=$(rm -f temp.txt && " & built_file & " " & full_input_file & " >> temp.txt && tail -n 1 temp.txt && rm -f temp.txt)"
        let command = test_command & " && " & full_command & " && echo \"" & file_parts.name & " $FULL_RESULT $TEST_RESULT\" >> " & results_file
        exec(command)
        # exec("FULL_RESULT=$(" & built_file & " " & full_input_file & ") >> " & results_file & " 2>&1 && echo \"" & file_parts.name & ": $FULL_RESULT\" >> " & results_file)
