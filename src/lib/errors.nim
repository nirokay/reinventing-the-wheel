import std/[terminal]

proc panicProgramError*(message: string) =
    stderr.styledWriteLine fgRed, "[Error] ", fgDefault, message
    quit 1
proc panicUserError*(message: string) =
    stderr.styledWriteLine fgRed, "[Error] ", fgDefault, message
    quit 2

proc warningError*(message: string) =
    stderr.styledWriteLine fgRed, "[Error] ", fgDefault, message

proc info*(message: string) =
    stderr.styledWriteLine fgYellow, message, fgDefault
