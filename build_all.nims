mode = ScriptMode.Verbose

import std/os
import std/strutils

# echo 
for file in listFiles(thisDir()):
    let file_parts = splitFile(file)
    # Check if name starts with "day"
    if file_parts.ext == ".nim" and file_parts.name.startsWith("day"):
        echo file_parts