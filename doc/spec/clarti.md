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
printf("Hello, %s!", read("%s", 100))
```

Asynchronously, it is a big longer, but still simple:
```lua
program.start(function()
  printf("Hello, %s!", read("%s", 100))
end)
```
----

#####Function Index

1. print
- read
- printf
- logf

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

######Logf

Log to standard output a formatted string, prepending `[T] ::` where `T` is the computer time, as returned by `os.clock`. `logf` also writes to the file `/kernel.log`.

```lua
logf('Hello, world!')
```

**NOTE:** logf does append a new line character _(`\n`)_ at the end of the stream.

----

#####Asynchronous Programming

A huge part of modern operating systems is multi-threading. This enables computers to do more then one task at the same time.

In reality, the operating system is in control of switching between tasks, for example, when `thread1` opens a file, the _scheduler_ will switch to `thread2`, execute that until it yields, and then switch to every thread, before switching back to `thread1`.

----

#####Object Index

1. libprog
  - daemonize
  - create


###### libprog.daemonize

While `libprog.daemonize` is not asynchronous in itself, it can help in creating event-handler threads and programs.

Libprog.daemonize takes no arguments, and returns an empty `daemon`.

- `libprog.daemonize():addEvent`
  `:addEvent` creates a new event handler entry in the daemon's list of events. It takes 2 arguments, the first one being the name of the event and the second one being a handler function.

  **Example:**
    ```lua
    local libprog = require 'libprog'

    libprog.daemonize()
      :addEvent('hello', function(event, who) printf("Hello, %s!", who) end)
    ```

  This specific example creates a new daemon, then, assigns the function `function(event, who) printf("Hello, %s!", who) end` to handle the event `hello`. The handler function can take a variable number of arguments, but the first one is the name of the event.


- `libprog.daemonize():start`
  `:start` creates a function to handle passed events, and runs it. It takes a variable number of arguments, and those are passed to the event-handling function.

  The specific function created looks a little like this:
  ```lua
  local args = {...} -- make a table out of the passed arguments
  for k, v in pairs(evs) do -- iterate over the passed event handler table
    if args[1] == k then -- does the first argument (event name) equal the name of the event we're looking at?
      for e, d in pairs(v) do -- It does. Call any handlers.
        pcall(d, ...) -- Safely call.
      end
    end
  end
  ```

  **Example:**
  ```lua
  local libprog = require 'libprog'

  libprog.daemonize()
    :addEvent('hello', function(event, who) printf("Hello, %s!", who) end)
    :run('hello', 'World')
  ```
  This example creates a daemon, assigns the function to the event, and runs said function (because `"hello" == "hello"`) with the parameters _'hello', 'world'_. Can you guess what this program does? You guessed it; It prints out 'Hello, World!'.
