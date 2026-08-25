import std/[]
import ./commands, ./flags, ./errors

let commandLine: CommandLine = parseCommandLine()

proc verifyUniqueness(list: ref seq[Command]) =
    var commands: seq[string]
    for command in list[]:
        for flag, value in commandLine.flags:
            if flag in commands:
                stderr.writeLine("Flag '" & flag & "' is not unique for command: " & command.desc)
            commands.add flag


proc execAllCommands*(list: ref seq[Command], PROGRAM: string) =
    ## Goes through all commands and executes `exec`

    # Verify every flag is unique, only in non-release builds:
    when not defined release:
        list.verifyUniqueness()

    for command in list[]:
        for flag, value in commandLine.flags:
            if flag notin command.names: continue
            if command.accepts.isSome():
                let accepts: CommandArgument = get command.accepts
                if accepts.default.isSome():
                    if accepts.default.get() != "" and value == "": panicUserError("Flag '" & flag & "' cannot be empty, expected some type of '" & accepts.argType & "'.")
            command.exec(value)
