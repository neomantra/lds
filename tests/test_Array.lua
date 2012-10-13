--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.Array
--]]

local ffi = require 'ffi'
local lds = require 'lds/Array'

local double_t = ffi.typeof('double')

local da_t = lds.ArrayT( double_t )

local da = da_t( 10 )

assert( #da == 10 )
assert( da:size() == 10 )
assert( not da:empty() )

assert( da:get(0) == 0 )

assert( da:set(3, 5) == 0 )
assert( da:get(3) == 5 )
