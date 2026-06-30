import std/[terminal, strutils]
import lib/all

const
    PROGRAM = "cat"
    DESCRIPTION = "Concatenate files and print to stdout."
    VERSION = "1.0.0"

let cmd: CommandLine = parseCommandLine()

var lineNumbers: bool = false

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["line-numbers", "l"], "Add line numbers infront of each line.",
        proc(_: string) = lineNumbers = true
    )
]
list.insertDefaultCommands()
list.execAllCommands()


let rawFiles: seq[string] = cmd.arguments
var validFiles: seq[array[2, string]]
for file in rawFiles:
    try:
        let content: string = file.readFile()
        validFiles.add([file, content])
    except OSError:
        warningError("No such file or directory: '" & file & "'")

proc catFile(file: array[2, string]) =
    var content: seq[string] = file[1].split("\n")
    if lineNumbers:
        let maxLine: int = content.len()
        for i, line in content:
            let number: int = i + 1
            content[i] = align($number & " | ", len($maxLine) + 4) & line
    echo content.join("\n")

if rawFiles.len() != 0:
    # Write files to STDOUT:
    for i, file in validFiles:
        if validFiles.len() > 1:
            let
                sep: string = "-"
                width: int = terminalWidth()
                line: string = repeat(sep, 3) & " " & file[0] & " " & repeat(sep, width)
            stderr.writeLine (if i != 0: "\n" else: "") & line[0 .. max(0, width - 1)] & "\n"
        file.catFile()
else:
    # Write STDIN to STDOUT:
    info("No files provided, reading from STDIN.")
    let content: string = stdin.readAll()
    catFile(["STDIN", content])
