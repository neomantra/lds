--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

HashMap

A map implemented as a chained hash table.

Implementation is based on ChainedHashTable at opendatastructures.org:
http://opendatastructures.org/ods-cpp/5_1_Hashing_with_Chaining.html

TODO: fixup hash function
TODO: allow 64-bitop in LuaJIT 2.1
TODO: option table as: { alloc = AllocatorFactory, hash = fn, eq = fn }
TODO: reserve buckets, e.g. unordered_map::reserve, max_load_factor

Conventions:
    private cdata fields are prefixed with _
    private class fields (via metatable) are prefixed with __
    private methods are prefixed with HashMapT__
--]]


local lds = require 'lds/hash'
require 'lds/Vector'

local ffi = require 'ffi'
local C = ffi.C

local bit = require 'bit'
local blshift, brshift, bor, bxor = bit.lshift, bit.rshift, bit.bor, bit.bxor


local PairT_cdef = [[
struct {
    $ key;
    $ val;
}
]]


local HashMapT_cdef = [[
struct {
    $ * _t; // lds.Vector<PairT>
    int _tsize;
    int _size;
    int _dim;
    int _z;
}
]]


local function HashMapT__hash( self, x )
    return brshift(
        (self._z * tonumber(x)), -- lds.hash(x)),
        (32 - self._dim) )  -- HashMapT__w = 32
end


local function HashMapT__resize( self )
    self._dim = 1
    while blshift(1, self._dim) <= self._size do self._dim = self._dim + 1 end
    local shift_dim = blshift( 1, self._dim )
    if shift_dim == self._tsize then return end  -- don't need to resize

    local ptr = self.__talloc:allocate( shift_dim )
    local new_t = ffi.cast( self._t, ptr )
    for i = 0, shift_dim-1 do
        self.__vt.__construct(new_t[i])
    end

    for i = 0, self._tsize-1 do
        for j = 0, self._t[i]._size-1 do
            local pair = self._t[i]._data[j]
            new_t[HashMapT__hash(self, pair.key)]:push_back(pair)
        end
        self.__vt.__destruct( self._t[i] )
    end
    self.__talloc:deallocate( self._t )

    self._t = new_t
    self._tsize = shift_dim
end


-- HashMap public methods
local HashMap = {}


------------------------------
-- Capacity methods

--- Returns the number of elements in the HashMap. 
-- 
-- This is the number of elements in the HashMap, not necessarily the total allocated memory.
--
-- The __len metamethod returns the same value so you can use the # operator
--
-- If you are seeing performance warnings with -jv (e.g. loop unroll limit),
-- it can also be accessed as the field `_size`, but you should never write
-- to this youself.
--
-- @return Returns the number of elements in the HashMap. 
function HashMap:size()
    return self._size
end


--- Returns true if the HashMap is empty.
-- @return true if the HashMap size is 0, false otherwise.
function HashMap:empty()
    return self._size == 0
end


------------------------------------
-- Element Access functions
--

--- Get key/value pair at key `k`.
--
-- Returns nil if the key is not found.
--
-- @param k Key of the element to find.
-- @return The key/value pair at the specified key in the HashMap.
function HashMap:find( k )
    local list = self._t[HashMapT__hash(self, k)]
    for i = 0, list._size-1 do
        local pair = list._data[i]
        if k == pair.key then return pair end
    end
    return nil
end


--- Returns an iterator, suitable for the Lua `for` loop, over all the pairs of the HashMap.
-- Each iteration yields an single object with fields `key` and `val`.
-- As this is a chained hash map. there is no logical order to the iteration.
--
-- Modify the HashMap (via insert/remove/clear) during iteration 
-- invalidates the iterator. *BE CAREFUL!*
--
-- @return iterator function
function HashMap:iter()
    -- i: index over all the buckets 
    -- j: index within a bucket
    local i, j = 0, -1
    return function()
        local t = self._t[i]
        j = j + 1
        while j >= t._size do
            i, j = i + 1, 0
            if i >= self._tsize then return nil end
            t = self._t[i]
        end
        return t._data[j]
    end
end



------------------------------
-- Modifier functions


--- Inserts element value `v` at key `k`.
--
-- Returns the previous value, if it existed, or true if it did not.
--
-- @param k Key to set in the HashMap.
-- @param v Element to set at that key
--
-- @return The previous element at the specified key in the HashMap,
-- or true if this is a new key.
function HashMap:insert( k, v )
    local pair = self:find( k )
    if pair then -- if it exists, update the value
        local old_val = pair.val
        pair.val = v
        return old_val
    end

    if (self._size + 1) > self._t._size then HashMapT__resize(self) end
    local j = HashMapT__hash(self, k) 
    -- initialization of nested structs are not compiled,
    -- so we use a pre-allocated placeholder, `_pt_scratch`, stored in the metatable
    -- otherwise, this would just be: self.t[j]:push_back(self.__pt(k, v))
    local pt = self.__pt_scratch
    pt.key, pt.val = k, v
    self._t[j]:push_back(pt)
    self._size = self._size + 1
    return true
end


--- Remove element at given key.
-- @param  k  Key to remove
-- @return The item previously at the key, or nil if absent.
function HashMap:remove( k )
    local list = self._t[HashMapT__hash(self, k)]
    for i = 0, list._size-1 do
        local y = list._data[i]
        if k == y.key then
            local old_val = y.val
            list:erase( i )
            self._size = self._size - 1
            return old_val
        end
    end
    return nil
end


--- Clears all the elements from the HashMap.
-- The allocated memory is reclaimed.
function HashMap:clear()
    self._size = 0
    HashMapT__resize( self )
end


------------------------------
-- Testing functions

-- Returns a Lua table with internal information about the HashMap.
--
-- This table has keys: tsize, size, dim, z, and buckets
-- 'buckets' is an array of tables with keys `size` and `cap`, representing
-- the size and capacity of the i'th bucket.
--
-- Generally for diagnostics
function HashMap:get_internals()
    local t = {
        tsize   = self._tsize,
        size    = self._size,
        dim     = self._dim,
        z       = self._z,
        buckets = {},  -- size, cap
    }
    for i = 0, self._tsize-1 do
        t.buckets[#t.buckets+1] = {
            size = self._t[i]._size,
            cap  = self._t[i]._cap,
        }
    end
    return t
end


------------------------------
-- Metatable

local HashMapT_mt = {
    
    __new = function( hmt )
        local ptr = hmt.__talloc:allocate( 2 )
        local hm = ffi.new( hmt,
            ptr,                               -- _t
            2,                                 -- _tsize
            0,                                 -- _size
            1,                                 -- _dim
            bor(math.random(0x7FFFFFFF), 1)    -- _z, a random odd integer
                                               --     HashMapT__w = 32
        )
        for i = 0, hm._tsize-1 do
            hm.__vt.__construct(hm._t[i])
        end
        return hm
    end,

    __gc = function( self )
        for i = 0, self._tsize-1 do
            self.__vt.__destruct(self._t[i])
        end
        self.__vt.__alloc:deallocate( self._t )
    end,

    --- __len metamethod, returning the number of elements in the HashMap. 
    -- See also HashMap:size() and HashMap._size
    -- @return The number of elements in the HashMap. 
    __len = function( self )
        return self._size
    end,

    __index = HashMap,
}


function lds.HashMapT( ct_key, ct_val, allocator_class )
    if type(ct_key) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end
    if type(ct_val) ~= 'cdata' then error("argument 2 is not a valid 'cdata'") end
    allocator_class = allocator_class or lds.MallocAllocator

    local pt = ffi.typeof( PairT_cdef, ct_key, ct_val )
    local vt = lds.VectorT( pt, allocator_class )
    local hmt = ffi.typeof( HashMapT_cdef, vt )  -- HashMap<key, val> ct

    -- clone the metatable and insert type-specific data
    local hmt_mt = lds.simple_deep_copy(HashMapT_mt)
    hmt_mt.__index.__ct_key = ct_key    -- the key ct
    hmt_mt.__index.__ct_val = ct_val    -- the value ct
    hmt_mt.__index.__pt = pt            -- the pair ct
    hmt_mt.__index.__pt_size = ffi.sizeof(pt)
    hmt_mt.__index.__vt = vt            -- the VectorT<pair> ct
    hmt_mt.__index.__vt_size = ffi.sizeof(vt)
    hmt_mt.__index.__pt_scratch = pt()  -- pre-allocated PairT
    hmt_mt.__index.__talloc = allocator_class(vt)

    return ffi.metatype( hmt, hmt_mt )
end


function lds.HashMap( ct_key, ct_val, allocator )
    return lds.HashMapT( ct_key, ct_val, allocator )()
end


-- Return the lds API
return lds
