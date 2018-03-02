--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

@type Array

Fixed-sized array of FFI cdata.

<p>Array is a fixed-sized container.
Index counting starts at zero, rather than Lua's one-based indexing.

Conventions:
    private cdata fields are prefixed with _
    private class fields (via metatable) are prefixed with __

--]]

local lds = require 'lds/allocator'

local ffi = require 'ffi'
local C = ffi.C


local ArrayT__cdef = [[
struct {
    $ *    _data;
    size_t _size;
}
]]


-- Array public methods
local Array = {}


----------------------
-- Capacity functions
----------------------

--- Returns the number of elements (not bytes) in the Array.
--
-- It can also be accessed witht the # operator.

-- If you are seeing performance warnings with -jv (e.g. loop unroll limit),
-- it can also be accessed as the field `_size`, but you should never write
-- to this youself.
--
-- @return Returns the number of elements (not bytes) in the Array.
function Array:size()
    return self._size
end


--- Returns true if the Array is empty.
-- This is only true for 0-size arrays.
-- @return true if the Array size is 0, false otherwise.
function Array:empty()
    return self._size == 0
end


--- Returns the size of the Array in bytes (not elements)
-- @return Returns the number of bytes (not elements) in the Array.
function Array:size_bytes()
    return self._size * self.__ct_size
end


----------------------------
-- Element Access functions

--- Returns the element at index `i` in the Array.
--
-- @param i Index of the element to get.
-- @return The element at the specified index in the Array, or `nil` if the index is out of bounds.
-- See also Array:get_e, which throws an error instead.
--
-- Note that the first element has an index of 0, not 1.
--
function Array:get( i )
    if i < 0 or i >= self._size then return nil end
    return self._data[i]
end


--- Returns the element at index `i` in the Array.
--
-- @param i Index of the element to get.
-- @return The element at the specified index in the Array.
--
-- If this is greater than or equal to the Array size, an "ArrayT.get: index out of bounds" error is thrown.
-- See also Array:get, which returns `nil` instead.
--
-- Note that the first element has an index of 0, not 1.
--
function Array:get_e( i )
    if i < 0 or i >= self._size then lds.error("ArrayT.get: index out of bounds") end
    return self._data[i]
end


--- Returns the value of the first element of the Array.
-- Returns `nil` if the Array is empty.
-- @return Returns the value of the first element of the Array, or `nil` if the Array is empty.
function Array:front()
    if self._size == 0 then return nil end
    return self._data[0]
end


--- Returns the value of the last element of the Array.
-- Returns `nil` if the Array is empty.
-- @return Returns the value of the last element of the Array, or `nil` if the Array is empty.
function Array:back()
    if self._size == 0 then return nil end
    return self._data[self._size - 1]
end


--- Returns a pointer to the underlying array.
--- @return Pointer to the underlying array.
function Array:data()
    return self._data
end


------------------------------
-- Modifier functions

--- Set element value at index.
-- Sets the element `x` at index `i` in the Array.
--
-- Returns nil if the index is out of range.
-- See also Array:set_e, which throws instead.
--
-- @param i Index to set in the Array.
-- @param x Element to set at that index
--
-- Note that the first element has an index of 0, not 1.
--
-- @return The previous element at the specified index in the Array,
-- or nil if the index is out of range.
function Array:set( i, x )
    if i < 0 or i >= self._size then return nil end
    local prev = self._data[i]
    self._data[i] = x
    return prev
end


--- Set element value at index.
-- Sets the element `x` at index `i` in the Array.
--
-- Throws error if the index is out of range.
-- See also Array:set, which returns `nil` instead.
--
-- @param i Index to set in the Array.
-- @param x Element to set at that index.
-- If this is greater than or equal to the Array size, the error "ArrayT.set: index out of bounds" is thrown.
--
-- Note that the first element has an index of 0, not 1.
--
-- @return The previous element at the specified index in the Array.
function Array:set_e( i, x )
    if i < 0 or i >= self._size then lds.error("ArrayT.set: index out of bounds") end
    local prev = self._data[i]
    self._data[i] = x
    return prev
end


------------------------------
-- Private methods

-- Constructor method
function Array:__construct( size )
    local data = self.__alloc:allocate(size)
    if not data then lds.error('ArrayT.new allocation failed') end
    self._data, self._size = data, size
    return self  -- for chaining
end


-- Destructor method
function Array:__destruct()
    self.__alloc:deallocate(self._data)
    self._data, self._size = nil, 0
    return self  -- for chaining
end


------------------------------
-- Metatable

local ArrayT__mt = {

    __new = function( at, size )
        local self = ffi.new(at)
        return self:__construct(size)
    end,

    __gc = function( self )
        self:__destruct()
    end,

    --- __len metamethod, returning the number of elements in the Array. 
    -- See also Array:size() and Array._size
    -- @return The number of elements in the Array. 
    __len = function( self )
        return self._size
    end,

    __index = Array,
}


function lds.ArrayT( ct, allocator_class )
    if type(ct) ~= 'cdata' then lds.error("argument 1 is not a valid 'cdata'") end
    allocator_class = allocator_class or lds.MallocAllocator

    -- clone the metatable and insert type-specific data
    local at_mt = lds.simple_deep_copy(ArrayT__mt)
    at_mt.__index.__ct = ct
    at_mt.__index.__ct_size = ffi.sizeof(ct)
    at_mt.__index.__alloc = allocator_class(ct)

    local at = ffi.typeof( ArrayT__cdef, ct )
    return ffi.metatype( at, at_mt )
end


function lds.Array( ct, size, allocator_class )
    return lds.ArrayT( ct, allocator_class )( size )
end


-- Return the lds API
return lds
