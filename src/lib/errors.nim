import std/[terminal]

proc panicProgramError*(message: string) =
    styledEcho fgRed, message, fgDefault
    quit 1
proc panicUserError*(message: string) =
    styledEcho fgRed, message, fgDefault
    quit 2
