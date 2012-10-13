
# lds - LuaJIT Data Structures

## Introduction

**lds** provides containers, such as lists, maps, and hash tables, which hold [LuaJIT *cdata*](http://luajit.org/ext_ffi_api.html).   

The **lds** implementation is adapted from the libraries at [opendatastructures.org](http://opendatastructures.org), with its interface changed to be closer to the C++ [Standard Template Library (STL)](http://www.cplusplus.com/reference/stl/).  

The LuaJIT FFI enables the instantiation and manipulation of C objects directly in Lua; these objects called *cdata*.  Although *cdata* may be stored in Lua tables, they are subject to a 4GB memory limit and GC inefficiency [^1].  Furthermore, a developer may want more application-specific complexity characteristics than what a generic Lua table offers.

**IMPORTANT:**  **lds** requires recent LuaJIT FFI features (parameterized types and __new metamethod).  These were added in June 2012, after beta10 was released.

## Example

The following example shows a *cdata* being held in a HashMap, mapping ID numbers to elements. 

```lua
local ffi = require 'ffi'
local lds = require 'lds/Vector'

ffi.cdef([[
struct Item {
    int    id;
    char   name[16];
    int    inventory;
};
]])

local Item_t = ffi.typeof( 'Item' )

-- Create a Vector and add some items
local v = Vector( Item_t )
v:push_back( Item_t( 100, "Apple",  42 ) )
v:push_back( Item_t( 101, "Orange", 10 ) )
v:push_back( Item_t( 102, "Lemon",   6 ) )
assert( v:size() == 3 )
assert( v:get(0).id == 100 )
```

Documentation for each container is pretty sparse right now, but the source is pretty readable.  Also look in the [test scripts](https://github.com/neomantra/lds/tree/master/tests).

## Containers

**lds** provides a variety of containers.  Most of these interfaces are based on the C++ Standard Template Library](http://www.cplusplus.com/reference/stl/).  To understand the implementations and theory, consult the [opendatastructures.org](http://opendatastructures.org/ods-cpp/) ("ODS") documentation.

  * Array-Based sequences ([ODS](http://opendatastructures.org/ods-cpp/2_Array_Based_Lists.html))

    * Array - a static array, akin to [std::array](http://www.cplusplus.com/reference/stl/array/).

    * Vector - a dynamic array with an interface based on [std::vector](http://www.cplusplus.com/reference/stl/vector/).  This is a good alternative to storing *cdata* in a Lua table and using [table.insert](http://www.lua.org/manual/5.1/manual.html#pdf-table.insert) / [table.remove](http://www.lua.org/manual/5.1/manual.html#pdf-table.remove). ([ODS](http://opendatastructures.org/ods-cpp/2_1_Fast_Stack_Operations_U.html))

    * Queue - a FIFO (first-in-first-out) queue, backed by an array, with an interface based on [std::queue](http://www.cplusplus.com/reference/stl/queue/). ([ODS](http://opendatastructures.org/ods-cpp/2_3_Array_Based_Queue.html))

    * Deque - a double-ended queue, backed by an array, with an interface based on [std::deque](http://www.cplusplus.com/reference/stl/deque/).  ([ODS](http://opendatastructures.org/ods-cpp/2_4_Fast_Deque_Operations_U.html)).  **not well tested**

 * Next highest priority (for the author) is HashMap and HashSet… available soon.  After that, probably RedBlackTree to get std::set and std::map.

## Installation

This library is currently only available as a [GitHub repo](https://github.com/neomantra/lds).  

To install, clone the repo and put the contained **lds** directory somewhere on your LUA_PATH.

  
## Usage

For each container type `Container`, there are two constructor functions: `ContainerT` and `Container` .  `ContainerT` takes a FFI `ct` and returns a `ctype` which can be used to create multiple containers of the same type.   `Container` takes a FFI `ct` and returns an actual container object.

```lua
local double_t = ffi.typeof('double')

-- Use the T form to create a new type and instantiate some queues.
local dq_t = lds.ArrayQueueT( double_t )
local q1 = dq_t()
local q2 = dq_t()

-- Use the regular form to directly create a queue
-- This is less efficient if you are creating many queues of the same type.
local q = lds.ArrayQueue( double_t )
```

**All indexed access is 0-based, *not* 1-based.**


## TODO

  * Implement ChainedHashTable and RedBlackTree
  
  * Test Deque
  
  * Document each class

  * Rockspec

  * Implement the rest of ODS?  Here's what's available:
    * Array-based Lists: DualArrayDeque, RootishArrayStack
    * Linked Lists:  SLList, DLList, SEList
    * Skiplists:  SkiplistSSet, SkiplistList
    * Hash Tables:  LinearHashTable
    * Binary Trees:  BinaryTree, BinarySearchTree, Treap, ScapegoatTree, 
    * Heaps:  BinaryHeap, MeldableHeap
    * Graphs:  AdjacencyMatrix, AdjacencyLists
    * Integer Structures: BinaryTrie, XFastTrie, YFastTrie

  * Iterators

  * Allocators (currently use malloc/free)
    * realloc in model?

  * Algorithms


## Support

Please submit feature requests and bug reports at the [Issues page on Gihub](http://github.com/neomantra/lds/issues).


## Contributors

  * Evan Wies <evan@neomantra.net>


## Acknowledgements

Many thanks to Professor Pat Morin for a well written textbook and readable implementations, both released with open licences.  Read and learn at [opendatastructures.org](http://opendatastructures.org).


## LICENSE

**lds** is distributed under the [MIT License](http://opensource.org/licenses/mit-license.php).

> lds - LuaJIT Data Structures
> 
> Copyright (c) 2012 Evan Wies.  All rights reserved
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Footnotes

  [^1]: [Discussion of LuaJIT memory and GC limits.](http://lua-users.org/lists/lua-l/2010-11/msg00241.html)

