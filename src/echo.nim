import std/[strutils]
import lib/all

const
    PROGRAM = "echo"
    DESCRIPTION = "Echoes provided arguments to stdout."
    VERSION = "1.0.0"

let cmd: CommandLine = parseCommandLine()

var
    trailingNewLine: bool = true
    escapeCharacters: bool = false
    indentOutput: bool = false
    indentNumber: int = 4

const escapeSequences: seq[array[2, string]] = @[
    ["\\n", "\n"],
    ["\\t", "\t"],
    ["\\r", "\r"],
    ["\\b", "\b"],
    ["\\a", "\a"]
]

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["no-new-line", "n"], "Removes trailing new line character.",
        proc(_: string) =
            trailingNewLine = false
    ),
    newCommand(@["escape", "e"], "Escapes escape sequences.",
        proc(_: string) =
            escapeCharacters = true
    ),
    newCommand(@["indent", "i"], "Indents output by a number of spaces.",
        proc(number: string) =
            indentOutput = true
            try: indentNumber = number.parseInt()
            except ValueError: discard,
        some CommandArgument(
            name: "number",
            argType: $int,
            default: $indentNumber
    ))
]
list.insertDefaultCommands()
list.execAllCommands()

let output: string = block:
    var r: string = cmd.arguments.join(" ")
    if escapeCharacters:
        for repl in escapeSequences:
            r = r.replace(repl[0], repl[1])
    if indentOutput:
        r = r.indent(indentNumber)
    r

stdout.write output & (if trailingNewLine: "\n" else: "")
