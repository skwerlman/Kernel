Command-Line Application Runtime Interface
==========================================

(Also: Common Lua Application Runtime Interface)

------------------------------------------------

####Preface

The need of a standardized API for ComputerCraft applications has troubled the community since the first operating systems were developed. The application programming interfaces made avaiable by frameworks such as Bedrock or NovaUI, that change unpredictably and erradically, are not enough.

This is why CLARTI was developed, to be a stable API that is consistent across operating systems, and can be used to write universal applications, anywhere, and deploy them, everywhere. However, while the core functionality is standardized and stable, things can be appended to the standard and modified at any time.

----

###Section 1
----
#####Basic Functionality  

Basic input and output is provided by the _clarti.io_ module, and contains the following functions. Basic I/O contains things such as `write`, `read`, `logf` and `printf`. Those functions provide the most basic of functionality a command-line application should do: Interfacing  with the user, in the most basic possible way.

Creating an application that interfaces with the user using _Clarti_ is easy. The simple, "Hello, what's your name?" application is implemented in one single line:

```lua
printf("Hello, %s!", scanf("%s", 100))
```

Asynchronously, it is a big longer, but still simple:
```lua
program.start(function()
  printf("Hello, %s!"m scanf("%s", 100))
end)
```
----

#####Function Index

1. print
- read
- printf
- logf
- scanf
- puts
- putd
- write

######Print

Print is the most basic way of output. It prints a simple, unformatted string to the standard output, evading the buffer.
```lua
  print("Hello, world!")
```
This classic program, a staple of programming, when executed under a Clarti-conformant environment, just outputs `hello world` on the screen, followed by a new line character _(`\n`)_, and exits.

######Printf

Printf, another staple of programming, prints a formatted string to standard output and returns nothing. Printf _should_ be buffered, but this is implementation dependent.

```lua
  printf("Hello, %s!", "World")
```

**NOTE:** printf does not append a new line character _(`\n`)_ at the end of the line.


######Read

Read an unformatted string from standard input. The return value is a simple string, representing what the user typed until he pressed enter.

```lua
function ask(question)
  printf("%s?", question)
  return read()
end
```
