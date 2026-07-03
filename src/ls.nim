import std/[strutils, os, algorithm, options]
import lib/all

const
    PROGRAM = "ls"
    DESCRIPTION = "List files and directories."
    VERSION = "1.0.0"

let cmd: CommandLine = parseCommandLine()

type
    FsItem = object
        kind*: PathComponent
        path*: string
        info*: Option[FileInfo]
    Sorting = enum
        byDefault, byAlphabet, bySize

var
    listHiddenFiles: bool = false
    longListing: bool = false
    columns: int = 4
    shorting: int = 0
    sortBy: Sorting = byDefault
    ignoreCase: bool = false
    sortingReversed: bool = false

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["all", "a"], "List hidden files/dotfiles.",
        proc(_: string) = listHiddenFiles = true
    ),
    newCommand(@["long", "l"], "Long listing.",
        proc(_: string) = longListing = true
    ),
    newCommand(@["columns", "c"], "Specify amount of columns.",
        proc(number: string) =
            try:
                columns = parseInt(number)
                if columns < 1: panicUserError("Columns has to be a positive integer.")
            except ValueError:
                panicUserError("Columns has to be a positive integer."),
        some CommandArgument(
            name: "number",
            argType: $int,
            default: some $columns
        )
    ),
    newCommand(@["shorting", "s"], "Shorten file/directory names when exceeding specified length.",
        proc(number: string) =
            try:
                shorting = number.parseInt()
                if shorting < 1: panicUserError("Shorting value has to be a positive integer.")
            except ValueError:
                panicUserError("Shorting value has to be a positive integer."),
        some CommandArgument(
            name: "number",
            argType: $int,
            default: some $shorting
        )
    ),
    newCommand(@["alphabetical", "A"], "Sort output alphabetically.",
        proc(_: string) =
            if sortBy != byDefault: panicUserError("Sorting can only be done by either alphabet or size.")
            sortBy = byAlphabet
    ),
    newCommand(@["ignore-case", "I"], "Ignore case for alphabetical sort.",
        proc(_: string) = ignoreCase = true
    ),
    newCommand(@["size", "S"], "Sort output by size.",
        proc(_: string) =
            if sortBy != byDefault: panicUserError("Sorting can only be done by either alphabet or size.")
            sortBy = bySize
    ),
    newCommand(@["reverse", "R"], "Reverse sorting.",
        proc(_: string) = sortingReversed = true
    )
]
list.insertDefaultCommands()
list.execAllCommands()

let workingDir: string = getCurrentDir()
var validDirs: seq[string]

for dir in cmd.arguments:
    if dirExists(dir): validDirs.add dir.replace("~", getHomeDir())

proc getSorted(entries: seq[FsItem]): seq[FsItem] =
    proc a(x, y: FsItem): int =
        let
            xp: string = if ignoreCase: x.path.toLower() else: x.path
            yp: string = if ignoreCase: y.path.toLower() else: y.path
        if not sortingReversed: cmp(xp, yp)
        else: cmp(y.path, x.path)
    proc s(x, y: FsItem): int =
        let
            xs: int = x.info.get(FileInfo(size: -1)).size
            ys: int = y.info.get(FileInfo(size: -1)).size
        if not sortingReversed: cmp(ys, xs)
        else: cmp(ys, xs)

    result = entries
    case sortBy:
    of byDefault: discard
    of byAlphabet: result.sort(a)
    of bySize: result.sort(s)
proc listDirectory(dir: string, multiple: bool = false) =
    var
        lines: seq[string]
        entries: seq[FsItem]

    if multiple: lines.add dir & ":"
    for kind, p in walkDir(dir):
        let path = p.splitPath().tail
        if not listHiddenFiles and path.startsWith("."): continue
        var item = FsItem(
            kind: kind,
            path: path.splitPath().tail,
        )
        try:
            item.info = some path.getFileInfo()
        except OSError:
            discard
        entries.add item

    if sortBy != byDefault: entries = entries.getSorted()

    for entry in entries:
        echo entry.path
    echo lines.join("\n")

if validDirs.len() == 0: listDirectory(".")
else:
    for i, dir in validDirs:
        listDirectory(dir, validDirs.len() > 1)
        if i != validDirs.len() - 1: echo ""
