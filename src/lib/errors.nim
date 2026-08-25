import std/[terminal]

template panicProgramError*(message: string) =
    stderr.styledWriteLine fgRed, "[", PROGRAM, " error] ", fgDefault, message
    quit 1
template panicUserError*(message: string) =
    stderr.styledWriteLine fgRed, "[", PROGRAM, " error] ", fgDefault, message
    quit 2

template warningError*(message: string) =
    stderr.styledWriteLine fgRed, "[", PROGRAM, " error] ", fgDefault, message

template info*(message: string) =
    stderr.styledWriteLine fgYellow, "[", PROGRAM, " info] ", message, fgDefault
