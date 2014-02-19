--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

lds module initialization 

--]]


local ffi = require 'ffi'
ffi.cdef([[
void *memmove(void *dst, const void *src, size_t len);
]])


-- API Table used by all other lds modules
local lds = {}


--- Error function called when the LDS library has an error
-- You may replace this function.
-- The default implementation calls Lua's error().
-- @param msg    The error message
function lds.error( msg )
    error( msg )
end


--- Assert function called by the LDS library
-- You may replace this function.
-- The default implementation is simply: if not x then lds.error(msg) end
-- @param x      The value to evaluate as true
-- @param msg    The error message
function lds.assert( x, msg )
    if not x then lds.error(msg) end
end


-- simple deep copy function
-- used to copy prototypical metatables
local function simple_deep_copy( x )
    if type(x) ~= 'table' then return x end
    local t = {}
    for k, v in pairs(x) do
        t[k] = simple_deep_copy(v)
    end
    return t
end
lds.simple_deep_copy = simple_deep_copy


-- Commonly used types
lds.int32_t  = ffi.typeof('int32_t')
lds.uint32_t = ffi.typeof('uint32_t')
lds.size_t   = ffi.typeof('size_t')


-- Constants
lds.INT_MAX = tonumber( lds.uint32_t(-1) / 2 )
lds.INT32_MAX = tonumber( lds.uint32_t(-1) / 2 )


-- Return the lds API
return lds
