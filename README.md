# TARDIX KERNEL

_Multithreaded_ kernel for **ComputerCraft** inspired by 4.4BSD and Linux.


#####Documentation

The documentation of TARDIX is present under _/doc_. <br>
The main file is _/doc/main.md_. It contains the documentation for booting the kernel and starting up.

The [tron paul boot loader](http://github.com/TARDIX/Tron_Paul) is the main method for booting TARDIX. The _debug bootloader_ is also present in this repository, under _/startup_.

#####Booting

The booting process is made of 4 main parts:
1. Creating a capable environment<br>
  The environment required for booting involves a capable _base64_ decoder. Extracting the kernel is easy. It can either be extracted to a virtual folder, the real file system, or deleted once _systemw_ calls the shell.

2. Decoding the _LAR_ file<br>
  The mainline kernel is released as a _LAR_ file. Lua Archive Balls, or _LARBalls_ as they are called in code consist of a _TARDIX inode table_, serialized into a Lua table, then encoded using _base64_.

3. Extracting the _LAR_ file<br>
  To extract the LAR file, you need to open each file in the _inode table_: It contains a _.meta.path_ element. You need to ```open()``` the _meta.path_ element in write mode, then write to that file the _.data_ element. If not in a computercraft-compliant environment, there is also a _.meta.size_ element you can use. It contains the size of the file, as reported by ```fs.getSize()```, in bytes.

4. Loading the Kernel<br>
  Finally, the computer is now in the right state for loading the main kernel file. ```/kernel/main.lua``` is the file you should load. Simply loading the file, using<br>
  ```lua
    loadfile('/kernel/main.lua')()
  ```
  is enough.


#####After Booting, what to do?

The mainline kernel, provided here, as a simple _worker_ (a form of _daemons_) called systemw. _Systemw_, a name derived from _system worker_, is the main method of loading the usermode programs. By default, it'll run the _modw_ (from _module worker_) to load the required kernel-mode modules and exit into the caller.

**WARNING: if using the Tron Paul boot loader, the system will be caught in a reboot loop. The default Tron Paul configuration of _tardix /kernel.lar_ does not exit after loading the kernel.**

**It is recommended to add an _exit_ instruction after the _tarix /kernel.lar_ instruction in the _/.tp-rc_ file.**
