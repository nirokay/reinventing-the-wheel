import std/[options]
export options

type
    CommandArgument* = object
        name*: string
        argType*: string
        default*: string
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
            echo PROGRAM & " - " & DESCRIPTION

            if list[].len() != 0:
                echo "\nOptions:"
                var lines: seq[string]
                for cmd in list[]:
                    var line: seq[string]
                    var l: seq[string]
                    for name in cmd.names:
                        if name.len() == 1: l.add "-" & name
                        else: l.add "--" & name
                    line.add "  " & l.join(", ")
                    if cmd.accepts.isSome():
                        let
                            accepts = get cmd.accepts
                            action: string = if accepts.default != "": "Accepts" else: "Requires"
                        line.add "    " & action & " [" & accepts.argType & "]" & (
                            if accepts.default != "": " default: '" & accepts.default & "'"
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
