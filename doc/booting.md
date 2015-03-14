#Booting
**_NOTE: This file details the booting process, providing metacode examples._**
**_DO NOT use the code provided as actual code._**


####Stages of the Boot Process

The TARDIX kernel booting process is composed of 4 stages. *Preparing the environment*, *Decoding the LAR*, *Extracting the LAR* and finally *Loading the Kernel.*



#####Step 1: Preparing the environment

To prepare the _larball_ for extraction, you first need a _base64_decode_ routine.

The _[Tron Paul bootloader](http://github.com/)_ can provide a simple base64 decode rountine, called `dec`. Use the `env: &dec;` instruction before the `lua /kernel/main.lua`. Alternatively, if using the `tardix /kernel.lar` instruction, the kernel is automagimatically extracted, and executed.

Also required in the environment is a `logf` routine. The logf routine provided in the _debug bootloader_ is the standard, but it can be improved. A basic logf routine is provided below.

``` coffee-script
  @logf = (fmt, ...) ->
    print (fmt).format(...)
```

That's not the best implementation, but it certainly works.


#####Step 2: Decoding the larball

Now that you have prepared the environment, the next step in booting TARDIX is decoding the lar file. A LAR, short for  _Lua ARchive_, is a base64-encoded, serialized _TARDIX inode table_. To decode a larball, call your previously-defined _base64_decode_ routine.

``` coffee
  # Decode the Larball
  @decode = (file) ->
    return base64_decode(file.readAll())
```

Now that the larball is decoded, let's proceed to extract it, in

#####Step 3: Extracting the Larball

The larball, a simple encoded _TARDIX inode table_, is extracted by reading the _meta.path_ property of an inode, then proceeding to write the _data_ property of said inode, and repeating for each inode on the table.

``` coffee

  #Extract the larball, finally.

  @extract = (data) ->
    for i in data ->
      open(i.meta.path, 'w').write i.data

```

Now that the larball is decoded, extracted, and the environment is set up, we can finally load the main file in


#####Step 5: Loading the Kernel

Now that everything is ready, TARDIX can safely be initialized. We have decoded and extracted the release larball, prepared the environment to be CC-compliant, and we're finally ready to call the main routine. This is the easiest step. It's actually the simplest code-wise too. The metacode for loading the main kernel file is just..

```coffee
  @load = (file) ->
    do_loadfile(file).exec()
```

Now, the kernel is finally booted, and it's proceeding to load the _system worker_.
The _system worker_ is the main _worker_ (a type of _daemon_) nescessary for system executing. It's responsible for loading all other _workers_ in the system, such as the _module worker_. The _module worker_ is responsible for loading all other _modules_ in the system. Modules in the current release, **2015-MARCH**, are: _larball_, _base64_, _base64/streams_, _larball/self-extracting_, _thread_ and _load_. _Load_ and _thread_ are fundamental for the system to work.

__Altho the module worker uses threads, it uses it's own standalone, independent, local implementation.<br>
The booting process does not depend on modules.__
