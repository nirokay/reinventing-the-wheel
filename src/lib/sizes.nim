import std/[strutils, math]

type
    SizeUnitFormat* = enum
        uRaw = 0,
        u1000 = 1000,
        u1024 = 1024

const
    units1000: array[11, string] = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "RB", "QB"]
    units1024: array[11, string] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB", "RiB", "QiB"]

proc getFileSizeDisplay*(size: int, format: SizeUnitFormat): string =
    if format == uRaw: return $size
    let units: array[11, string] = (case format:
        of u1000: units1000
        of u1024: units1024
        of uRaw: units1024 # will not happen anyways
    )
    var
        unitId = 0
        value: float = size.toFloat()
    while unitId < units.len() - 1:
        if value < toFloat(int format): break
        value = value.ceil() / toFloat(int format)
        inc unitId

    result = block:
        var parts: seq[string] = split($value, ".")
        if parts[1] == "0": parts[0]
        else:
            parts[0] & "." & parts[1][0 .. min(1, parts[1].len())]

    result &= units[unitId]
