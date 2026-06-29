import std/[strutils]
import lib/all

const
    PROGRAM = "debug"
    DESCRIPTION = "Used for debugging libraries."
    VERSION = "0.1.0"

var list: ref seq[Command] = new seq[Command]
list[].add newCommand(@["flags", "f"], "Tests flags and args.",
    proc(_: string) =
        let cmd: CommandLine = parseCommandLine()
        echo "Flags:"
        for key, val in cmd.flags:
            echo "\t" & key & (if val == "": "" else: " = " & val)
        if cmd.arguments.len() != 0:
            echo "Arguments:"
            for arg in cmd.arguments:
                echo "\t" & arg
)
list.insertDefaultCommands()

list.execAllCommands()
