
# lds - LuaJIT Data Structures

[![Travis Status](https://travis-ci.org/neomantra/lds.svg?branch=master)](https://travis-ci.org/neomantra/lds)

**lds** provides data structures which hold [LuaJIT *cdata*](http://luajit.org/ext_ffi_api.html).   

These containers cover the common use cases of Lua *tables*:

  * Array (fixed-size array)
  * Vector (dynamically-sized array)
  * HashMap (key-value store)

## Installation

This library is currently only available as a [GitHub repo](https://github.com/neomantra/lds):
```
git clone https://github.com/neomantra/lds.git
```

To install, clone the repo and copy `lds.lua` and the **lds** directory (the one *inside* the repo) to somewhere on your LUA_PATH.  To use, simply `require` the module and use the returned value:
```
local lds = require 'lds'
```


## Example

The following example shows a *cdata* being stored in a Vector and then retrieved from there are stored in a HashMap.

```lua
local ffi = require 'ffi'
local lds = require 'lds'

ffi.cdef([[
struct Item {
    int    id;
    char   name[16];
    int    inventory;
};
]])

local Item_t = ffi.typeof('struct Item')

-- Create a Vector and add some items
local v = lds.Vector( Item_t )
v:push_back( Item_t( 100, 'Apple',  42 ) )
v:push_back( Item_t( 101, 'Orange', 10 ) )
v:push_back( Item_t( 102, 'Lemon',   6 ) )
assert( v:size() == 3 )
assert( v:get(0).id == 100 )
assert( v:get(2).id == 102 )

-- Now create a HashMap of Item id to Item
-- Note this is stored by-value, not by-reference
local map = lds.HashMap( ffi.typeof('int'), Item_t )
for i = 0, v:size()-1 do  -- lds.Vector is 0-based
    local item = v:get(i)
    map:insert( item.id, item )  
end
assert( map:size() == 3 )
assert( map:find(100).key == 100 )
assert( map:find(100).val.inventory == 42 )
assert( map:find(102).key == 102 )
assert( map:find(102).val.inventory == 6 )

```

## Motivation

Lua provides a powerful data structure called a *table*.  A table is an heterogeneous associative array -- its keys and values can be any type (except *nil*).
  
The [LuaJIT FFI](http://luajit.org/ext_ffi.html) enables the instantiation and manipulation of C objects directly in Lua; these objects called *cdata*.  Although *cdata* may be stored in Lua tables (but [are not suitable as keys](http://luajit.org/ext_ffi_semantics.html#cdata_key)), when used this way they are subject to a [4GB memory limit and GC inefficiency](http://lua-users.org/lists/lua-l/2010-11/msg00241.html).

**lds** provides the containers Array, Vector, and HashMap, which cover the common use cases of Lua *tables*.  However, the memory of these containers are managed through user-specified allocators (e.g. *malloc*) and thus are not subject to the LuaJIT memory limit.  It is also significantly lower load on the LuaJIT Garbage Collector.

One drawback to be aware of is that **lds** containers are homogeneous.  A given container has explicitly one key type and one *cdata* value type.  


# API

Documentation for this library is pretty sparse right now -- try reading the [test scripts](https://github.com/neomantra/lds/tree/master/tests).

The source is well documented and the implementation is decently readable -- much easier than an STL implementation.

  
## Caveats

  * Array and Vector indices are 0-based, **not** 1-based.

  * Raw memory allocators are used, not the LuaJIT __new/__gc system, so you can only store simple data.  In other words, if your cdata allocates memory or other resources, you will need to manage that manually. 

  * Right now the hash function is identity (hash(x) = x), so keys are limited to simple numeric types and pointers.

  * Although raw memory allocators are used, they may allocate memory in the range which LuaJIT desires.  The impact of this depends on which allocator you use and your OS.


## TODO

  * ldoc in wiki
  * TODOs in HashMap
  * Rockspec


## Support

Submit feature requests and bug reports at the [Issues page on GitHub](http://github.com/neomantra/lds/issues).


## Contributors

  * Evan Wies


## Acknowledgments

Many thanks to Professor Pat Morin for a well written textbook and readable implementations, both released with open licenses.  HashMap is based on his [ChainedHashTable](http://opendatastructures.org/ods-cpp/5_1_Hashing_with_Chaining.html).   Read and learn at [opendatastructures.org](http://opendatastructures.org).


## LICENSE

**lds** is distributed under the [MIT License](http://opensource.org/licenses/mit-license.php).

> lds - LuaJIT Data Structures
> 
> Copyright (c) 2012-2014 Evan Wies.  All rights reserved
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

