import std/[terminal, strutils]
import lib/all

const
    PROGRAM = "cat"
    DESCRIPTION = "Concatenate files and print to stdout."
    VERSION = "1.0.0"

let cmd: CommandLine = parseCommandLine()

type HeadTail = enum
    opNone, opHead, opTail
var
    lineNumbers: bool = false
    headTail: HeadTail = opNone
    headTailLines: int = 10

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["line-numbers", "l"], "Add line numbers infront of each line.",
        proc(_: string) = lineNumbers = true
    ),
    newCommand(@["head"], "Only print the first X lines.",
        proc(_: string) =
            if headTail == opNone: headTail = opHead
            else: panicUserError("You have to select either head or tail.")
    ),
    newCommand(@["tail"], "Only print the last X lines.",
        proc(_: string) =
            if headTail == opNone: headTail = opTail
            else: panicUserError("You have to select either head or tail.")
    ),
    newCommand(@["numbers", "n"], "Specifies how many first or last lines are printed with head/tail.",
        proc(n: string) =
            try:
                headTailLines = n.parseInt()
                if headTailLines < 1: panicUserError("Must be a positive integer for --numbers.")
            except ValueError: panicUserError("Invalid integer provided for --numbers."),
        some CommandArgument(
            name: "number",
            argType: $int,
            default: $headTailLines
        )
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

proc minAboveZero(x, y: int): int =
    result = min(x, y)
    if result < 0: result = 0
proc maxAboveZero(x, y: int): int =
    result = max(x, y)
    if result < 0: result = 0

proc catFile(file: array[2, string]) =
    var content: seq[string] = file[1].split("\n")
    if lineNumbers:
        let maxLine: int = content.len()
        for i, line in content:
            let number: int = i + 1
            content[i] = align($number & " | ", len($maxLine) + 4) & line
    let output: string = block:
        case headTail:
        of opNone: content.join("\n")
        of opHead: content[0 .. minAboveZero(headTailLines - 1, content.len() - 1)].join("\n")
        of opTail: content[maxAboveZero(content.len() - headTailLines, 0) .. ^1].join("\n")
    echo output

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
