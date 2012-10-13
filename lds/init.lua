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


-- Return the lds API
return lds
