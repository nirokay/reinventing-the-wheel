import std/[terminal, base64]
import lib/all

const
    PROGRAM = "base64"
    DESCRIPTION = "Base64 encoder/decoder."
    VERSION = "1.0.0"

let cmd: CommandLine = parseCommandLine()

type Operation = enum
    opUnspecified, opEncode, opDecode
var
    operation: Operation = opUnspecified
    file: string
    payload: string

var list: ref seq[Command] = new seq[Command]
list[] = @[
    newCommand(@["payload", "p", "text", "t"], "Payload/Text to encode/decode, instead of file.",
        proc(text: string) = payload = text
    ),
    newCommand(@["file", "f"], "Encode/Decode file contents.",
        proc(name: string) = file = name
    ),
    newCommand(@["encode", "e"], "Encode plain text to base64.",
        proc(_: string) =
            if operation != opUnspecified: panicUserError("You have to select either encode or decode.")
            operation = opEncode
    ),
    newCommand(@["decode", "d"], "Decode base64 to plain text.",
        proc(_: string) =
            if operation != opUnspecified: panicUserError("You have to select either encode or decode.")
            operation = opDecode
    )
]
list.insertDefaultCommands()
list.execAllCommands()

proc performOperation(payload: string) =
    var result: string
    try:
        case operation:
        of opUnspecified: panicUserError("Operation not selected, select either encode or decode.")
        of opEncode: result = encode(payload)
        of opDecode: result = decode(payload)
    except ValueError:
        case operation:
        of opUnspecified: panicProgramError("Error whilst encoding provided data. Also operation is not specified.")
        of opEncode: panicProgramError("Error whilst encoding provided data.")
        of opDecode: panicUserError("Invalid base64 data.")
    echo result

if operation == opUnspecified: panicUserError("Operation not selected, select either encode or decode.")
if payload != "":
    # Handle payload provided through argument
    performOperation(payload)
elif file != "":
    # Handle payload from file
    try:
        performOperation(file.readFile())
    except OSError:
        panicUserError("No such file or directory: '" & file & "'")
else:
    # Handle payload from STDIN:
    performOperation(stdin.readAll())
