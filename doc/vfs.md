#The VFS
**WARNING: The VFS module is still experimental.**


So, you want to access a network file system? Good good.

```lua
local _nfs = dev.getFileSystem('/dev/net')
local sock = _nfs.open('/dev/net/my_socket', READ, CREATE)

-- Socket is prepared, read stuff.

local data = _nfs.read(sock, 10, 1) --[[
  Read 10 lines from the Socket 'sock', skipping 1 line.
]]

_nfs.close(sock)

-- Write data.

local sock = _nfs.open('/dev/net/my_socket', WRITE, CREATE)

_nfs.write(sock, "Hello, world!")

_nfs.close(sock)

-- Data written.

```

Now that's all well and dandy, but *what if you want to use the same function, for multiple devices, with runtime mode manipulation?* Well, that's **_impossible_™**.. But, no.


With the TARDIX virtual file file system, that's the way things go.
Need to open a network device? `vfs.open` is there for you. Need to open a file in a base64-encoded, mounted lua archive ball? Guess what, `vfs.open` is there for you.

The VFS packed with TARDIX has several functions, but the main one, is, _you guessed it,_ `vfs.open`. `vfs.open` is the main function for opening all sorts of devices, with all sorts of device drivers, anywhere in the system. In fact, the VFS is so useful, a compile-time option before packing the kernel is to replace the computercraft FS api with the VFS api!

Oh, one more thing: **RUNTIME. MODE. MANIPULATION.** You heard right, ladies and gentleman. No more needing to open and close those pesky files over and over.

Now, let's be done with the humour and START THE DOCS!


*awesome music plays in the background*


#####Opening a file with the TARDIX VFS

As you learned in the previous, _humorous_ section, the way of opening files is `vfs.open`.

```lua
--annex 1: vfs.open use case

local data = vfs.open("/dev/net/socket.10", DYN, CREATE)
  :opts(WO)
  :write('Hello, world!')
  :opts(RO)
  :read(10, 10) -- 10+10th line
  :close()
```

The method chaining here is provided by a buffered input and output system. Every time you read or readAll, it pushes the result into a buffer, the `in` buffer. In the other hand, every time you write or append, it pushes to the `out` buffer. When you :close(), the `in` buffer is returned, and the `out` buffer is flushed into the handle.

Internally, `vfs.open` looks at the device path, then compares it to a list of root device paths and their respecive drivers, finds the best driver to use and calls the driver's internal functions. The [TARDIX driver standard](http://example.com) was created to ease communication of the drivers and the VFS.

One example of a concrete, standard-compliant driver is the TFS driver. The TFS (_Tardix File System_, internal `tfs`) is actually the modeling factor for the driver standard. It complies with the standard, and the standard complies with it.

The Tardix File System is the main file system used in TARDIX. It is not used to mount partitions, or anything of the sorts. Instead, it is a nicely-wrapped library for interacting with the actual computer's file system. It provides many of the methods other drivers use for abstraction, such as `_core_open`,  `_core_buffer` and others. All file systems and device drivers are, therefore, an extension of sorts of the TFS.
