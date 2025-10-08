# zat

`zat` is my personal version of the `cat` command, rewritten in Zig (0.15.1).

## Features

* Reads and prints files to stdout.
* Supports multiple input files.
* Common options inspired by `cat`:

  * `-n` — number all output lines.
  * `-b` — number non-blank output lines.
  * `-E` — display `$` at the end of each line.
  * `-T` — display tabs as `^I`.(not implemented yet)
  * `-v` — show non-printable characters in a visible form (partial).(not implemented yet)
* Unix-friendly behavior: when no file is passed, it reads from stdin.
* Line-buffered output for interactive use.

## Requirements

* Zig (0.15.1). Download from [https://ziglang.org](https://ziglang.org).
* A UNIX-like environment (Linux, macOS recommended). Not Tested on Windows
## Project Structure

```
zat/
├─ src/
│  └─ main.zig
├─ build.zig
├─ README.md
├─ LICENSE
└─ .gitignore
```

## Build

### Quick method (single file)

If the project is organized as a single `src/main.zig`:

```bash
zig build --summary all
```

This generates the executable `zat` under the zig-out/bin/ directory.

## Usage Examples

Print a file:

```bash
zat file.txt
```

Concatenate multiple files:

```bash
zat a.txt b.txt
```

Read from stdin:

```bash
echo "hello" | zat
```

Number all lines:

```bash
./zat -n file.txt
```

Number only non-empty lines:

```bash
zat -b file.txt
```


## Contributing

This repo is my personal space, but PRs and suggestions are welcome. Open an issue for ideas or bugs.

## License

This project is released under the MIT License — see the `LICENSE` file for details.

## Roadmap

* Finish implementing all the flags of cat

