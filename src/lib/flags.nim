import std/[parseopt, os, tables]
export tables

type
    Flag* = object
        key*, value*: string
    CommandLine* = object
        flags*: OrderedTable[string, string]
        arguments*: seq[string]

proc getSplits(raw: seq[string]): array[2, seq[string]] =
    ## `[0]` contains a mixture of flags and args, while `[1]` certainly only contains args
    var triggeredStop: bool = false
    for i, part in raw:
        if triggeredStop:
            result[1].add part
        else:
            if part == "--":
                triggeredStop = true
                continue
            else:
                result[0].add part

proc parseCommandLine*(): CommandLine =
    let parts: array[2, seq[string]] = getSplits(commandLineParams())
    for kind, key, value in getopt(parts[0]):
        case kind:
        of cmdArgument: result.arguments.add key
        of cmdLongOption, cmdShortOption: result.flags[key] = value
        of cmdEnd: discard
    result.arguments &= parts[1]

proc isSet*(commandLine: CommandLine, names: seq[string]): bool =
    ## Checks if is set/available
    for name in names:
        if commandLine.flags.hasKey(name): return true
proc getValue*(commandLine: CommandLine, names: seq[string]): string =
    ## Gets value
    for name in names:
        if commandLine.flags.hasKey(name): return commandLine.flags[name]
