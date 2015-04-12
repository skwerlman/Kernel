File System Hierarchy
=====================

In _TARDIX_, the files are usually arranged in a manner that makes sense. Programs go into /usr/bin, libraries into /usr/local, and configurations into /usr/etc.  
The full directory tree, however, is more complex. The recommended file system hierarchy, **derived from Chameleon's**, is defined as follows:  



```
root              (directory)
  L kernel        (directory)
    L kernel      (directory)
      L main.lua  (directory)
  L tsr           (directory)
    L bin         (directory)
      L init      (     file)
      L tlc       (     file)
    L lib         (directory)
      L libporte  (     file)
    L share       (directory)
      L laporte   (directory)
        L main    (     file)
    L etc         (directory)
      L laprote   (directory)
        L cache   (     file)
      L sysw.conf (     file)
  L home          (directory)
    L root        (     file)
    L user        (     file)
```

As you can see, the directory structure follows a simple, straight-forward structure: _TARDIX System Resources_ (tsr) is the root directory for **bin**aries, **lib**raries, **share**d files and **etc**etera (mostly configuration files).  


The second top-level directory is _kernel_, that contains the TARDIX kernel, generally in the form of a git submodule or as a virtual directory, mounted from a MIF.  


The next top-level directory is _home_, where the user's personal configuration files and documents should reside. It is the login manager's job to create and manage the _home_ directory, with no intervention from the kernel.

------------------------------

####Where Should a Program Go?

A program should go into as many directories as possible. This doesn't mean make a mess. **Instead, it means, _"keep stuff tidy"_**. Programs should go into 3 directories: _binaries go into /usr/bin, libraries into /usr/lib, and configuration files into /usr/etc/<program>. If your program is bad, and is self-contained, as an application package, place the whole thing under /usr/share._  

The _libporte_ package management backend, and therefore _porte_ and _laporte_, comply to this standard.
