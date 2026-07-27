import std/[os]
import lib/all

const
    PROGRAM = "pwd"
    DESCRIPTION = "Prints the current working directory."
    VERSION = "1.0.0"

var printFileUrls: bool = false

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["file-urls", "u"], "Prints clickable file urls.",
        proc(_: string) = printFileUrls = true
    ),
]

list.insertDefaultCommands()
list.execAllCommands()

let workingDir: string = (if printFileUrls: "file://" else: "") & getCurrentDir()
echo workingDir
