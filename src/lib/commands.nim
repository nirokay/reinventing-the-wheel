import std/[strutils, options]
export options

type
    CommandArgument* = object
        name*, argType*: string
        default*: Option[string]
    Command* = object
        names*: seq[string]
        desc*: string
        exec*: proc(value: string)
        accepts*: Option[CommandArgument]

proc newCommand*(names: seq[string], desc: string, exec: proc, accepts: Option[CommandArgument] = none CommandArgument): Command = Command(
    names: names,
    desc: desc,
    exec: exec,
    accepts: accepts
)

proc getCommandFlagRepr*(name: string): string =
    result =
        if name.len() == 1: "-" & name
        else: "--" & name

template addVersionCommand*(list: untyped): untyped =
    list[].insert(Command(
        names: @["version", "v"],
        desc: "Displays version of program.",
        exec: proc(_: string) =
            echo PROGRAM & " version " & VERSION
            quit 0
    ), 0)
template addHelpCommand*(list: untyped): untyped =
    list[].insert(Command(
        names: @["help", "h"],
        desc: "Displays this help text.",
        exec: proc(_: string) =
            echo @[PROGRAM, DESCRIPTION].join(" - ")

            if list[].len() != 0:
                echo "\nOptions:"
                var lines: seq[string]
                for cmd in list[]:
                    var
                        line: seq[string]
                        l: seq[string]
                    for name in cmd.names:
                        l.add name.getCommandFlagRepr()
                    line.add "  " & l.join(", ")
                    if cmd.accepts.isSome():
                        let accepts = get cmd.accepts
                        line[^1] &= " = <" & accepts.name & ": " & accepts.argType & ">" & (
                            if accepts.default.isSome():
                                " | " & accepts.default.get("?")
                            else: ""
                        )
                    line.add "    " & cmd.desc
                    lines.add line.join("\n")
                echo lines.join("\n\n")
            quit 0
    ), 0)
template insertDefaultCommands*(list: untyped): untyped =
    list.addVersionCommand()
    list.addHelpCommand()
