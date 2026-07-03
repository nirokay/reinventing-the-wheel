import std/[]
import ./commands, ./flags, ./errors

let commandLine: CommandLine = parseCommandLine()

proc execAllCommands*(list: ref seq[Command]) =
    ## Goes through all commands and executes `exec`
    for command in list[]:
        for flag, value in commandLine.flags:
            if flag notin command.names: continue
            if command.accepts.isSome():
                let accepts: CommandArgument = get command.accepts
                if accepts.default.isSome():
                    if accepts.default.get() != "" and value == "": panicUserError("Flag '" & flag & "' cannot be empty, expected some type of '" & accepts.argType & "'.")
            command.exec(value)
