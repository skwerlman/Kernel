Triplets
========

_Target triplets_ describe a platform for the Tardix Lua Compiler. Common targets you'll see outputted by the compiler or in the log file are _cc-adv-tardix-tabi_ or _cc-adv-tardix-elf_. The kernel library has a function for detecting the _host_ triplet, called `dump_arch`.


#####What are Triplets For?

Triplets are used by the compiler to determine target architecture and application binary interface.

The Application Binary Interface, _ABI_ for short, is very much like an _API_ for compiled programs. The API defines functions used in source-level, and the _ABI_ defines what those functions look like in machine-level.

#####TARDIX Triplets

The TARDIX target triplets are defined as *`<type>-tardix-<abi>`*. The type is as returned by `getComputerType` and the abi is `cclua` for all regular usages or `tabi` for compiled Lua code.
