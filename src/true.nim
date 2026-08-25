from std/strutils import parseInt
from std/strformat import `&`
import lib/all

const
    PROGRAM = "true"
    DESCRIPTION = "Exits with exit-code 0 or a custom one."
    VERSION = "1.0.0"

var exitCode: int = 0

proc newExit(number: int, names: seq[string], desc: string): Command =
    let description: string =  &"{desc} ({number})."
    result = newCommand(names, description,
        proc(_: string) = exitCode = number
    )

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["code", "C"], "Use this exit code [0..127].",
        proc(number: string) =
            try:
                exitCode = number.parseInt()
            except ValueError:
                panicProgramError("Exit code is not an integer.")
            if exitCode notin 0..127:
                panicProgramError("Exit code is not an integer in range of 0..127."),
        some CommandArgument(
            name: "number",
            argType: $int
        )
    ),
    newExit(1, @["false", "failure", "f"], "General failure"),
    newExit(2, @["misuse", "m"], "Misuse of command"),
    newExit(126, @["no-permission", "p"], "No permission"),
    newExit(127, @["not-found", "n"], "Not found")
]

list.insertDefaultCommands()
list.execAllCommands(PROGRAM)

quit exitCode
