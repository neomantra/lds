--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.HashMap
--]]

local ffi = require 'ffi'
local lds = require 'lds/HashMap'

local int_t = ffi.typeof('int')
local double_t = ffi.typeof('double')

local um_t = lds.HashMapT( int_t, double_t )  -- map from int to double
local um = um_t()

assert( #um == 0 )
assert( um:size() == 0 )
assert( um:empty() )

assert( um:insert(5, 24.0) == true)
assert( #um == 1 )
assert( um:size() == 1 )
assert( not um:empty() )

assert( um:find(5).key == 5 )
assert( um:find(5).val == 24.0 )
assert( um:insert(5, 22.0) == 24.0 )
assert( um:size() == 1 )

assert( um:remove(5) == 22.0 )
assert( um:remove(5) == nil )
assert( um:size() == 0 )

um:insert(5, 21.0)
um:insert(6, 22.0)
um:insert(7, 23.0)
um:insert(100054, 77.0)
assert( um:size() == 4 )
assert( um:find(5).val == 21.0 )
assert( um:find(6).val == 22.0 )
assert( um:find(7).val == 23.0 )
assert( um:find(100054).val == 77.0 )

um:clear()
assert( um:size() == 0 )
assert( um:empty() )
