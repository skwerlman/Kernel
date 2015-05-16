The Device Bus
--------------

[*(Back to index)*](https://github.com/TARDIX/Kernel/blob/rewrite/doc/index.md)

System calls are the main way for a library to interact with the isolated areas of the kernel.


#####Table of Contents

######Basic Concepts  
1. Calling the System

-------------

###Basic Concepts

#####1 - Calling the System

The way system calls work in TARDIX is very similar to the way they work in real-life operating systems. But, instead of firing an interrupt (for example, *0x80* on Linux), in TARDIX, you fire an event. Because there is no CPU-provided backing for system calls like there are interrupts in *x86* and *x86_64*, this requires a multi-threaded kernel.

One way to call the system is the one employed by libtblob, firing an event with `os.queueEvent` or the to-be sandboxed `coroutine.fire`. Follows an example of calling the system.

```lua
  os.queueEvent(
    'syscall', -- identifier for the event, much like the 0x80 interrupt code
    'sys_print', -- fist parameter for the system call executor, the name of the call
    'Hello, world!' -- from here on now, any parameters are passed to the system call itself. in this case, it's what gets printed.
  )
```

-------------

TARDIX is free software, developed under the [MIT License](http://opensource.org/licenses/MIT), by Matheus de A. (matheus.de.alcantara@gmail.com), Jared Allard (rainbowdashdc@mezgrman.de) and Brian Hodgins (bhodgins@9600-baud.net).
