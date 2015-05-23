The Device Bus
--------------

[*(Back to index)*](https://github.com/TARDIX/Kernel/blob/rewrite/doc/index.md)

The TARDIX Device Bus, more commonly known as TDB or simply _devbus_ is the primary way for system-level non-abstracted programs to interface with hardware.


#####Table of Contents

######Basic Concepts  
1. Drivers
2. Devices
  1. Classification
3. Device Table


-------------

###Basic Concepts

#####1 - Drivers

Drivers are the way for software not running in the kernel to override the functionality of a peripheral. They are standard Lua functions *assigned* to a certain type of device, and are called by *devbus* when a peripheral is being wrapped.

#####2 - Devices

A device refers to a wrapped peripheral, nicely packaged for easy access by the kernel. Unlike normal peripherals, devices have some functions that reroute the *peripheral API* calls.

#####2.1 - Device Classification

In vanilla, computercraft TARDIX, there are 5 types of devices. They are:
  - Character devices (printers, monitors and modems (both wired and wireless))
  - Computer devices (computers and turtles)
  - Block devices (currently just disk drives)
  - OPP devices (OpenPeripherals Peripherals)
  - and UTP devices (Un-typed peripherals, basically thosae that don't fit any of the above categories)


#####3 - Device Table

In TARDIX, the term *Device Table* is used to refer to a collection of devices, sorted by side. The global device table (the one that maps to `/dev` on the file system) englobes the entirety of connected devices.

A filesystem representation of the devices tree is avaiable under `/dev`. These nodes are not special files (for now), but in the future you'll be able to use ioctl, read, and write to control such devices. The `/dev` naming scheme is: `/`
-------------

TARDIX is free software, developed under the [MIT License](http://opensource.org/licenses/MIT), by Matheus de A. (matheus.de.alcantara@gmail.com), Jared Allard (rainbowdashdc@mezgrman.de) and Brian Hodgins (bhodgins@9600-baud.net).
