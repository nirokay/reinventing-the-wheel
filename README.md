# Reinventing the wheel

This is a monorepo of programs that already exist, but remade just for fun.

## Compiling

* `nimble build` `nimble build -d:release` -> binaries will be put into the `./bin/` subdirectory.
* `nimble install https://github.com/nirokay/reinventing-the-wheel`

The `install.sh` script appends a prefix to the binaries (`ls` -> `kls`), because of the default,
actually better, programs and moves the built binaries into path (`~/.local/bin`).

## Docs

| Program                  | Short description                      |
|--------------------------|----------------------------------------|
| [base64](docs/base64.md) | Base64 encoder/decoder.                |
| [cat](docs/cat.md)       | Concatenate files and print to stdout. |
| [echo](docs/echo.md)     | Writes to stdout.                      |
| [ls](docs/ls.md)         | List files and directories.            |
| [pwd](docs/pwd.md)       | Prints the current working directory.  |


## Licence

This project is licensed under the GPL-3.0 licence.
