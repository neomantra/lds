--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

@type Vector

Dynamic array of FFI cdata.

Index counting starts at zero, rather than Lua's one-based indexing.

--]]

local lds = require 'lds/allocator'

local ffi = require 'ffi'
local C = ffi.C


local VectorT__cdef = [[
struct {
    $ * __data;
    int __size;
    int __cap;
}
]]


-- Resizes the vector to reserve_n.
-- Like libstd++, it will resize to the larger of
-- reserve_n or double the capacity.
local function VectorT__resize( v, reserve_n, shrink_to_fit )
    local new_cap = math.max(1, reserve_n or 2*v.__cap, shrink_to_fit and 1 or 2*v.__cap)
    if v.__cap >= new_cap then return end

    local new_data = v.__alloc:reallocate(v.__data, new_cap*v.__ct_size)
    v.__data = ffi.cast( v.__data, new_data )
    v.__cap = new_cap
end 


-- Vector public methods
local Vector = {}


------------------------------
-- Capacity methods

--- Returns the number of elements in the Vector. 
-- 
-- This is the number of elements in the Vector, not necessarily the total allocated memory.
-- See vector:capacity.
--
-- The __len metamethod returns the same value so you can use the # operator
--
-- It can also be accessed as the field `__size`, although
-- you should never write to this youself.
--
-- @return Returns the number of elements in the Vector. 
function Vector:size()
    return self.__size
end


--- Returns the number of bytes used by objects in the Vector. 
-- 
-- @return Returns the number of bytes used by in the Vector. 
function Vector:size_bytes()
    return self.__size * self.__ct_size
end


--- Returns true if the Vector is empty.
-- @return true if the Vector size is 0, false otherwise.
function Vector:empty()
    return self.__size == 0
end


--- Returns the total number of elements the Vector can currently hold.
-- This is number of elements the Vector can hold before needing to allocate more memory.
-- @return The number of elements the Vector can hold before needing to allocate more memory.
function Vector:capacity()
    return self.__cap
end


--- Returns the number of bytes of capacity of the Vector. 
-- 
-- @return Returns the number of bytes of capacity by in the Vector. 
function Vector:capacity_bytes()
    return self.__cap * self.__ct_size
end


--- Request a change in capacity
--
-- Requests that the capacity of the allocated storage space for the elements of the vector
-- container be at least enough to hold `reserve_n` elements.
--
-- @param reserve_n Minimum amount desired as capacity of allocated storage, in elements of type T.
function Vector:reserve( reserve_n )
    VectorT__resize( self, reserve_n )
end


--- Attempts to free unused memory.
function Vector:shrink_to_fit()
    VectorT__resize(self, self.__size, true )  -- true = shrink_to_fit
end



------------------------------------
-- Element Access functions
--

--- Get element value at index.
-- Returns the element at index `i` in the vector.
--
-- Returns `false` if the index is out of range.
-- See also Vector:get_e which throws an error instead.
--
-- @param i Index of the element to get
-- If this is greater than or equal to the vector size, "VectorT.get: index out of bounds" error is thrown.
-- Notice that the first element has an index of 0, not 1.
--
-- @return The element at the specified index in the Vector.
function Vector:get( i )
    if i < 0 or i >= self.__size then return false end
    return self.__data[i]
end


--- Get element value at index.
-- Returns the element at index `i` in the vector.
--
-- Throws error if the index is out of range.
-- See also Vector:get, which returns `false` instead.
--
-- @param i Index of the element to get.
-- If this is greater than or equal to the vector size, "VectorT.get: index out of bounds" error is thrown.
-- Notice that the first element has an index of 0, not 1.
--
-- @return The element at the specified index in the vector.
function Vector:get_e( i )
    if i < 0 or i >= self.__size then lds.error("VectorT.get: index out of bounds") end
    return self.__data[i]
end


--- Returns the value of the first element of the Vector.
-- Returns `false` if the Vector is empty.
-- @return Returns the value of the first element of the Vector.
function Vector:front()
    if self.__size == 0 then return false end
    return self.__data[0]
end


--- Returns the value of the last element of the Vector.
-- Returns `false` if the Vector is empty.
-- @return Returns the value of the last element of the Vector.
function Vector:back()
    if self.__size == 0 then return false end
    return self.__data[self.__size-1]
end


--- Return pointer for the underlying array.
-- This can also be accessed as the field `__data`, although
-- you should never write to this yourself.
-- @return Pointer for the underlying array.
function Vector:data()
    return self.__data
end


------------------------------
-- Modifier functions


--- Set element value at index.
-- Sets the element `x` at index `i` in the Vector.
--
-- Returns false if the index is out of range.
-- See also Vector:set_e, which throws an error instead.
--
-- @param i Index to set in the Vector.
-- @param x Element to set at that index
--
-- Note that the first element has an index of 0, not 1.
--
-- @return The previous element at the specified index in the Vector,
-- or false if the index is out of range.
function Vector:set( i, x )
    if i < 0 or i >= self.__size then return false end
    local prev = self.__data[i]
    self.__data[i] = x
    return prev
end


--- Set element value at index.
-- Sets the element `x` at index `i` in the Vector.
--
-- Throws error if the index is out of range.
-- See also Vector:set, which returns `false` instead.
--
-- @param i Index to set in the Vector.
-- @param x Element to set at that index
-- If this is greater than or equal to the Vector size, the error "VectorT.set: index out of bounds" is thrown.
--
-- Note that the first element has an index of 0, not 1.
--
-- @return The previous element at the specified index in the vector.
function Vector:set_e( i, x )
    if i < 0 or i >= self.__size then lds.error("VectorT.set: index out of bounds") end
    local prev = self.__data[i]
    self.__data[i] = x
    return prev
end


--- Inserts given value into Vector at the specified index, move all element over.
-- @param  i  Index to insert at
-- @param  x  Data to be inserted.
--
-- This function will insert a copy of the given value before
-- the specified location.  Note that this kind of operation
-- could be expensive for a Vector and if it is frequently
-- used the user should consider using std::list.
function Vector:insert( i, x )
    if type(x) == 'nil' then self:push_back(i) end  -- handle default index like table.insert
    if i < 0 or i > self.__size then lds.error("insert: index out of bounds") end
    if self.__size + 1 > self.__cap then VectorT__resize(self) end
    C.memmove(self.__data+i+1, self.__data+i, (self.__size-i)*self.__ct_size)
    self.__data[i] = x
    self.__size = self.__size + 1
end


--- Add data to the end of the Vector.
-- @param  x  Data to be added.
--
-- This is a typical stack operation.  The function creates an
-- element at the end of the Vector and assigns the given data
-- to it.  Due to the nature of a Vector this operation can be
-- done in constant time if the Vector has preallocated space available.
function Vector:push_back( x )
    if self.__size + 1 > self.__cap then VectorT__resize(self) end
    self.__data[self.__size] = x
    self.__size = self.__size + 1
end


--- Remove element at given index.
-- @param  i  Index to erase 
-- @return The item previously at the index.
--
-- This function will erase the element at the given index and thus
-- shorten the Vector by one.
-- 
-- Note This operation could be expensive and if it is
-- frequently used the user should consider using std::list.
-- The user is also cautioned that this function only erases
-- the element, and that if the element is itself a pointer,
-- the pointed-to memory is not touched in any way.  Managing
-- the pointer is the user's responsibilty.
function Vector:erase( i )
    if type(i) == 'nil' then return self:pop_back() end  -- handle default index like table.remove
    if i < 0 or i >= self.__size then lds.error("VectorT.erase: index out of bounds") end
    local x = self.__data[i]
    C.memmove(self.__data+i, self.__data+i+1, (self.__size-i)*self.__ct_size)
    self.__size = self.__size - 1
    return x
end


--- Removes last element.
-- @return The value that was previously the last element, or false if the vector was empty.
-- This is a typical stack operation. It shrinks the Vector by one.
function Vector:pop_back()
    if self.__size == 0 then return false end
    local x = self.__data[self.__size - 1]
    self.__size = self.__size - 1
    return x
end


--- Clears all the elements from the Vector.  The allocated memory is unchanged.
function Vector:clear()
    self.__size = 0
end


------------------------------
-- Private methods

-- Constructor method
function Vector:__construct( reserve_n )
    if reserve_n and reserve_n > 0 then
        local data = self.__alloc:allocate(n)
        if not data then lds.error('VectorT.new allocation failed') end
        self.__data, self.__size, self.__cap = data, 0, reserve_n
    else
        self.__data, self.__size, self.__cap = nil, 0, 0
    end
    return self  -- for chaining
end


-- Destructor method
function Vector:__destruct()
    self.__alloc:deallocate(self.__data)
    self.__data, self.__cap, self.__size = nil, 0, 0
    return self  -- for chaining
end


------------------------------
-- Metatable

local VectorT__mt = {

    __new = function( vt, reserve_n )
        local self = ffi.new(vt)
        return self:__construct(reserve_n)
    end,

    __gc = function( self )
        self:__destruct()
    end,

    --- __len metamethod, returning the number of elements in the Vector. 
    -- See also Vector:size() and Vector.__size
    -- @return The number of elements in the Vector. 
    __len = function( self )
        return self.__size
    end,

    __index = Vector,
}


function lds.VectorT( ct, allocator_class )
    if type(ct) ~= 'cdata' then lds.error("argument 1 is not a valid 'cdata'") end
    allocator_class = allocator_class or lds.MallocAllocator

    -- clone the metatable and insert type-specific data
    local vt_mt = lds.simple_deep_copy(VectorT__mt)
    vt_mt.__index.__ct = ct
    vt_mt.__index.__ct_size = ffi.sizeof(ct)
    vt_mt.__index.__alloc = allocator_class(ct)

    local vt = ffi.typeof( VectorT__cdef, ct )
    return ffi.metatype( vt, vt_mt )
end


function lds.Vector( ct, allocator_class )
    return lds.VectorT( ct, allocator_class )()
end


-- Return the lds API
return lds
