import std/[strutils, strformat, os, algorithm, options, terminal, math, times, symlinks, paths]
import lib/all

const
    PROGRAM = "ls"
    DESCRIPTION = "List files and directories."
    VERSION = "1.0.1"

let cmd: CommandLine = parseCommandLine()

type
    FsItem = object
        kind*: PathComponent
        absolute*, relative*, name*: string
        info*: Option[FileInfo]
    Sorting = enum
        byDefault, byAlphabet, bySize, byDate
    WhichTime = enum
        lastWrite, lastAccess, firstCreation

const
    shortingMinLength: int = 5
    longListingItems: int = 7
    shortingSuffix: string = "..."
    columnSep: string = "  "
var
    listHiddenFiles: bool = false
    longListing: bool = false
    printFileUrls: bool = false
    printAbsolutePath: bool = false
    columns: int = 0
    longListingTime: WhichTime = lastWrite
    humanReadableSizes: bool = false
    humanSizesKilo: bool = false
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
    newCommand(@["file-urls", "u"], "Prints clickable file urls.",
        proc(_: string) = printFileUrls = true
    ),
    newCommand(@["full-path", "f"], "Prints absolute file path.",
        proc(_: string) = printAbsolutePath = true
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
    newCommand(@["shorting", "s"], &"Shorten file/directory names when exceeding specified length. Exceeded length will have '{shortingSuffix}' appended.",
        proc(number: string) =
            try:
                shorting = number.parseInt()
                if shorting < shortingMinLength: panicUserError(&"Shorting value has to be a positive integer >= {shortingMinLength}.")
            except ValueError:
                panicUserError(&"Shorting value has to be a positive integer >= {shortingMinLength}."),
        some CommandArgument(
            name: "number",
            argType: $int,
            default: some $shorting
        )
    ),
    newCommand(@["time-creation", "C"], "Display creation time instead of last write time in long listing.",
        proc(_: string) = longListingTime = firstCreation
    ),
    newCommand(@["time-last-access", "E"], "Display time of last access instead of last write time in long listing.",
        proc(_: string) = longListingTime = lastAccess
    ),
    newCommand(@["human-readable", "r"], "Display file sizes in human readable format.",
        proc(_: string) = humanReadableSizes = true
    ),
    newCommand(@["use-1000", "k"], "Human readable format in 1000s steps (eg. kilobyte) instead of 1024s (eg. kibibyte).",
        proc(_: string) = humanSizesKilo = true
    ),
    newCommand(@["alphabetical", "A"], "Sort output alphabetically.",
        proc(_: string) =
            if sortBy != byDefault: panicUserError("Sorting can only be done by either alphabet, size or date.")
            sortBy = byAlphabet
    ),
    newCommand(@["ignore-case", "I"], "Ignore case for alphabetical sort.",
        proc(_: string) = ignoreCase = true
    ),
    newCommand(@["size", "S"], "Sort output by size.",
        proc(_: string) =
            if sortBy != byDefault: panicUserError("Sorting can only be done by either alphabet, size or date.")
            sortBy = bySize
    ),
    newCommand(@["date", "D"], "Sort output by date.",
        proc(_: string) =
            if sortBy != byDefault: panicUserError("Sorting can only be done by either alphabet, size or date.")
            sortBy = byDate
    ),
    newCommand(@["reverse", "R"], "Reverse sorting.",
        proc(_: string) = sortingReversed = true
    )
]
list.insertDefaultCommands()
list.execAllCommands()

if longListing or printFileUrls:
    columns = 1
    shorting = 0

let requestedDirs: seq[string] = cmd.arguments
var validDirs: seq[string]
for dir in requestedDirs:
    let directory: string = dir.expandTilde()
    if dirExists(dir): validDirs.add directory
    else: warningError("Cannot find directory with name '" & directory & "'.")

proc getFsItem(path: string): FsItem =
    result = FsItem(
        name: path.splitPath().tail,
        relative: path,
        absolute: path.absolutePath()
    )
    try:
        result.info = some path.getFileInfo()
        result.kind = result.info.get().kind
    except OSError:
        discard
proc getFsItem(path: string, kind: PathComponent): FsItem =
    result = path.getFsItem()
    result.kind = kind

proc getFileDisplay(file: FsItem): string =
    result =
        if printFileUrls: "file://" & file.absolute
        elif printAbsolutePath: file.absolute
        else: file.name

    # Replace characters:
    for repl in @[
        ("'", "\\'"),
        ("\"", "\\\"")
    ]:
        result = result.replace(repl[0], repl[1])

    # Short names:
    block shortenNames:
        if shorting < shortingMinLength: break shortenNames
        if shorting >= result.len(): break shortenNames
        let
            cutoff: int = shorting - shortingSuffix.len() - 1
            shortened: string = block:
                var r: string = result[0 .. cutoff]
                # Remove trailing backslash, could fuck with piping:
                while r[^1] == '\\':
                    r = r[0 .. ^2]
                r
        if shortened != result: result = shortened & shortingSuffix

    # Quote when spaces:
    if " " in result:
        result = "'" & result & "'"

proc putInColumnsOf(items: seq[FsItem], cols: int): (seq[int], seq[FsItem]) =
    result =(
        newSeq[int](cols),
        newSeq[FsItem](items.len())
    )
    for id, item in items:
        try:
            let
                length: int = item.getFileDisplay().len()
                pos = divmod(id, cols)
                row: int = pos[0]
                col: int = pos[1]
            #[ fuck this shit, idk how to put it in columns vertically
                position: int = col * cols + row
                # position = row * cols + col
                newCol: int = position mod cols
            # echo &"{id} in {cols}: {col} * {cols} + {row} = {position}"
            # echo &"{id}: {row} * {cols} + {col} = {position}"
            ]#
            result[1][id] = item
            if length > result[0][col]: result[0][col] = length
            # echo item.getFileDisplay(), " ", length, " [", col, ", ", row, "]"
        except IndexDefect:
            echo "fuck"
proc putInMinimumCols(items: seq[FsItem]): (seq[int], seq[FsItem]) =
    var
        cols: int = 16
        finalColLengths: seq[int] = newSeq[int](cols)
        finalColumnedItems: seq[FsItem] = items

    while cols > 1:
        let
            #rows: int = int ceil(items.len().toFloat() / cols.toFloat())
            data: (seq[int], seq[FsItem]) = items.putInColumnsOf(cols)
            colLengths: seq[int] = data[0]
            columnedItems: seq[FsItem] = data[1]
            sepLen: int = max(0, columnSep.len() * (cols - 1))

        if colLengths.sum() + sepLen > terminalWidth():
            dec cols
        else:
            finalColLengths = colLengths
            finalColumnedItems = columnedItems
            break

    result = (finalColLengths, finalColumnedItems)

proc getLongListingDetails(item: FsItem): seq[string] =
    result = newSeq[string](longListingItems)
    if not longListing: return
    if item.info.isNone(): return

    let info: FileInfo = get item.info
    # Type:
    if info.isSpecial: result[0] = "*"
    result[0] &= (
        case info.kind:
            of pcLinkToFile, pcLinkToDir: "l"
            of pcFile: "f"
            of pcDir: "d"
    )

    # Hardlinks:
    result[1] = $info.linkCount

    # Size:
    result[2] = getFileSizeDisplay(info.size,
        if not humanReadableSizes: uRaw
        else:
            if humanSizesKilo: u1000
            else: u1024
    )

    # Permissions:
    let permissions: set[FilePermission] = (
        var r: set[FilePermission] = {}
        try:
            r = item.absolute.getFilePermissions()
        except CatchableError:
            discard
        r
    )

    for i, perms in [
        [fpUserExec, fpUserWrite, fpUserRead],
        [fpGroupExec, fpGroupWrite, fpGroupRead],
        [fpOthersExec, fpOthersWrite, fpOthersRead]
    ]:
        result[3] &= (
            case i:
                of 0: "U"
                of 1: "|G"
                of 2: "|O"
        )
        for i, perm in perms:
            result[3] &= (
                if perm in permissions:
                    case i:
                        of 0: "x"
                        of 1: "w"
                        of 2: "r"
                else: "-"
            )

    # Date:
    let
        t: Time = case longListingTime:
            of lastWrite: info.lastWriteTime
            of lastAccess: info.lastAccessTime
            of firstCreation: info.creationTime
            # lastWrite, lastAccess, firstCreation
        dt: DateTime = parse(replace($t, "T", "-"), "yyyy-MM-dd-HH:mm:sszzz") # 2026-07-19T10:45:41+02:00
        now: DateTime = now()
    result[4] = dt.format("MMMM")[0 .. 2]
    result[5] = dt.format("dd")
    let year: string = dt.format("yyyy")
    # Replace year with timestamp, if file write this year:
    if year == now.format("yyyy"):
        result[6] = dt.format("HH:mm")
    else:
        result[6] = year

proc prettyLongListingDetails(entries: seq[seq[string]]): seq[seq[string]] =
    var lengths: seq[int] = newSeq[int](longListingItems)
    for entry in entries:
        var r: seq[string] = entry
        for i in 0 .. longListingItems - 1:
            if r.len() < i: r.add @[]
            if r[i] == "": r[i] = "/"
            if r[i].len() > lengths[i]: lengths[i] = r[i].len()
        result.add r
    for i, entry in result:
        var r: seq[string] = entry
        for v, value in r:
            r[v] = align(value, lengths[v])
        result[i] = r


proc printEntry(item: FsItem, colLength: int, details: seq[string], full: bool = false) =
    let
        file: string = (
            if printFileUrls: item.getFileDisplay()
            elif full: item.relative
            else: item.getFileDisplay()
        )
        color: ForegroundColor = block:
            var r: ForeGroundColor = fgRed
            r = case item.kind:
                of pcFile: fgDefault
                of pcLinkToFile, pcLinkToDir: fgCyan
                of pcDir: fgBlue

            # Executable files:
            if item.info.isSome():
                let info: FileInfo = item.info.get()
                case item.kind:
                of pcFile:
                    if fpUserExec in info.permissions: r = fgGreen
                else: discard
            r
        style: Style = block:
            var r: Style
            if item.info.isSome():
                let info: FileInfo = item.info.get()
                if info.kind in [pcDir, pcLinkToDir]: r = styleBright
            r

    if details.len() != 0: stdout.write details.join(" ") & " "
    stdout.styledWrite style, color, file, fgDefault

    block tail:
        # Expand Symlinks in long listing:
        if longListing:
            if not symlinkExists(Path item.absolute): break tail
            stdout.write " -> "
            let
                path: Path = expandSymlink(Path item.absolute)
                target: FsItem = getFsItem(string path)
            printEntry(target, 20, @[], full = true)
        else:
            stdout.write repeat(" ", max(0, colLength - file.len()))
proc printEntries(entries: seq[FsItem]) =
    let
        data = if columns == 0: entries.putInMinimumCols() else: entries.putInColumnsOf(columns)
        colLengths: seq[int] = data[0]
        cols: int = colLengths.len()
        items: seq[FsItem] = data[1]

    var details: seq[seq[string]]
    if longListing:
        for item in items: details.add item.getLongListingDetails()

    if details.len() != 0:
        details = details.prettyLongListingDetails()

    for id, item in items:
        let
            col: int = id mod cols
            lastInRow: bool = col + 1 == cols
        item.printEntry(if longListing: 0 else: colLengths[col], if details.len() == 0: @[] else: details[id])
        if lastInRow: stdout.write "\n"
        elif id != items.len() - 1: stdout.write "  "
    stdout.write "\n"

proc getSorted(entries: seq[FsItem]): seq[FsItem] =
    proc a(x, y: FsItem): int =
        let
            xp: string = if ignoreCase: x.name.toLower() else: x.name
            yp: string = if ignoreCase: y.name.toLower() else: y.name
        if not sortingReversed: cmp(xp, yp)
        else: cmp(yp, xp)
    proc s(x, y: FsItem): int =
        let
            xs: int = x.info.get(FileInfo(size: -1)).size
            ys: int = y.info.get(FileInfo(size: -1)).size
        if not sortingReversed: cmp(ys, xs)
        else: cmp(xs, ys)
    proc d(x, y: FsItem): int =
        proc chooseTime(info: FileInfo): Time =
            case longListingTime:
                of lastWrite: info.lastWriteTime
                of lastAccess: info.lastAccessTime
                of firstCreation: info.creationTime
        let
            now: Time = getTime()
            ix: FileInfo = x.info.get(FileInfo(
                lastAccessTime: now,
                lastWriteTime: now,
                creationTime: now
            ))
            iy: FileInfo = y.info.get(FileInfo(
                lastAccessTime: now,
                lastWriteTime: now,
                creationTime: now
            ))
            xd: Time = ix.chooseTime()
            yd: Time = iy.chooseTime()
        if not sortingReversed: cmp(yd, xd)
        else: cmp(xd, yd)

    result = entries
    case sortBy:
    of byDefault: discard
    of byAlphabet: result.sort(a)
    of bySize: result.sort(s)
    of byDate: result.sort(d)
proc listDirectory(dir: string, multiple: bool = false) =
    var
        lines: seq[string]
        entries: seq[FsItem]

    if multiple: lines.add dir & ":"
    for kind, p in walkDir(dir):
        let name: string = p.splitPath().tail
        if not listHiddenFiles and name.startsWith("."): continue
        entries.add p.getFsItem(kind)

    if sortBy != byDefault: entries = entries.getSorted()

    if lines.len() != 0: echo lines.join("\n")
    entries.printEntries()

if requestedDirs.len() == 0: listDirectory(".")
else:
    for i, dir in validDirs:
        listDirectory(dir, validDirs.len() > 1)
        if i != validDirs.len() - 1: echo ""
