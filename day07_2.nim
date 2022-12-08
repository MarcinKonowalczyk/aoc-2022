import std/strutils
import std/algorithm

# let filename = "./data/test/day07_input.txt";
let filename = "./data/full/day07_input.txt";

type
    File = tuple
        name: string
        size: int64

    Directory = object
        name: string
        size: int64
        parent: ptr Directory
        directories: seq[Directory]
        files: seq[File]

proc newDirectory(name: string, parent: ptr Directory): Directory =
    result = Directory(
        name: name,
        size: 0,
        parent: parent,
        directories: @[],
        files: @[],
    )

proc addToSize(dir: var Directory, size: int64) =
    dir.size += size
    if dir.parent != nil:
        dir.parent[].addToSize(size)

proc addFile(dir: var Directory, name: string, size: int64) = 
    dir.files.add((name: name, size: size))
    dir.addToSize(size)

proc `in`(name: string, dir: Directory): bool =
    result = false
    for subdir in dir.directories:
        if subdir.name == name:
            result = true
            break
    # for filename in dir.files:
    #     if filename.name == name:
    #         result = true
    #         break

proc `notin`(name: string, dir: Directory): bool =
    result = not (name in dir)

let root = newDirectory("/", nil)
var cd: ptr Directory = unsafeAddr(root)

var i = 0
for line in lines(filename):
    # echo line
    let split_line = line.split(" ")
    if i == 0:
        assert(split_line[0] == "$")
        assert(split_line[1] == "cd")
        assert(split_line[2] == "/")
        i += 1
        continue

    if split_line[0] == "$":
        assert(split_line.len > 1)
        if split_line[1] == "cd":
            assert(split_line.len == 3)
            let name = split_line[2]
            if name == "..":
                cd = cd[].parent
            elif name notin cd[]:
                let new_dir = newDirectory(name, cd)
                cd[].directories.add(new_dir)
                cd = unsafeAddr(new_dir)
            else:
                var found = false
                for child in cd.directories:
                    if child.name == name:
                        cd = unsafeAddr(child)
                        found = true
                        break
                assert(found)
        elif split_line[1] == "ls":
            assert(split_line.len == 2)
        else:
            raise newException(ValueError, "Unknown command: " & split_line[1])
    else:
        assert(split_line.len == 2)
        if split_line[0] == "dir":
            let name = split_line[1]
            if name notin cd[]:
                cd[].directories.add(newDirectory(name, cd))
        else:
            let size = split_line[0].parseInt
            let name = split_line[1]
            cd[].addFile(name, size)

    i += 1


proc print(dir: Directory, indent: int = 0) =
    echo ' '.repeat(indent) & "- " & dir.name & " (dir, size=" & $dir.size & ")"
    for child in dir.directories:
        print(child, indent + 2)
    for file in dir.files:
        echo ' '.repeat(indent + 2) & "- " & file.name & " (file, size=" & $file.size & ")"

# root.print()

const DISK_SPACE = 70000000
const REQUIRED_SPACE = 30000000

let free_space = DISK_SPACE - root.size
echo "Free space: " & $free_space

let needs_to_delete = REQUIRED_SPACE - free_space
echo "Needs to delete: " & $needs_to_delete


proc toSeq(dir: Directory): seq[Directory] =
    result = @[]
    result.add(dir)
    for child in dir.directories:
        result.add(child.toSeq())

proc sorted(dir: Directory): seq[Directory] =
    result = dir.toSeq().sortedByIt(it.size)

var to_delete_size: int64 = -1
for dir in root.sorted():
    if dir.size > needs_to_delete:
        to_delete_size = dir.size
        # echo dir.name & " " & $dir.size
        break
assert(to_delete_size != -1)

echo to_delete_size
