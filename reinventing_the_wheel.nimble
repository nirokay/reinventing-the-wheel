# Package

version       = "0.1.0"
author        = "nirokay"
description   = "Reinventing the wheel: making programs that already exist for fun."
license       = "GPL-3.0-only"
srcDir        = "src"
binDir        = "bin"
bin           = @[
                    "echo",
                    "cat",
                    "base64",
                    "ls",
                    "pwd"
                ]

task release, "Build release versions.":
    exec "nimble build -d:release -d:danger"

# Dependencies

requires "nim >= 2.2.8"
