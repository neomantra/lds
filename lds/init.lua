--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

lds module initialization 

--]]


-- Currently lds is hard-coded to use free/malloc as an allocation scheme
local ffi = require 'ffi'
ffi.cdef([[
void *malloc(size_t size); 
void free(void *ptr); 
]])


-- API Table used by all other lds modules
local lds = {}


-- lds assert function
-- should this error() or return nil, msg?
function lds.assert( x, msg )
    if not x then error(msg) end
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


-- Constants
lds.INT_MAX = 2147483647


-- Return the lds API
return lds
