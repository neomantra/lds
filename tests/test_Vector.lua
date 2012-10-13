--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.Vector
--]]

local ffi = require 'ffi'
local lds = require 'lds/Vector'

local double_t = ffi.typeof('double')

local dv_t = lds.VectorT( double_t )

local dv = dv_t()

assert( #dv == 0 )
assert( dv:size() == 0 )
assert( dv:empty() )

dv:insert( 0, 6 )
assert( #dv == 1 )
assert( dv:size() == 1 )
assert( dv:get(0) == 6 )

dv:insert( 0, 5 )
assert( #dv == 2 )
assert( dv:size() == 2 )
assert( dv:get(0) == 5 )
assert( dv:get(1) == 6 )

assert( dv:set(1, 7) == 6 )
assert( dv:get(1) == 7 )

assert( dv:erase(0) == 5 )
assert( #dv == 1 )
assert( dv:size() == 1 )
assert( dv:get(0) == 7 )

dv:insert( 0, 5 )
dv:insert( 0, 5 )
dv:clear()
assert( #dv == 0 )
assert( dv:size() == 0 )
assert( dv:empty() )

dv:push_back( 2 )
assert( #dv == 1 )
assert( dv:size() == 1 )
assert( dv:get(0) == 2 )

assert( dv:pop_back() == 2 )
assert( #dv == 0 )
assert( dv:size() == 0 )
