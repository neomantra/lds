--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.HashSet
--]]

local ffi = require 'ffi'
local lds = require 'lds/HashSet'

local double_t = ffi.typeof('double')

local us_t = lds.HashSetT( double_t )
local us = us_t( double_t )

assert( #us == 0 )
assert( us:size() == 0 )
assert( us:empty() )

assert( us:insert(5) == true)
assert( #us == 1 )
assert( us:size() == 1 )
assert( not us:empty() )

assert( us:find(5) == 5 )
assert( us:insert(5) == false )

assert( us:remove(5) == 5 )
assert( us:remove(5) == nil )
assert( us:size() == 0 )

us:insert(5)
us:insert(6)
us:insert(7)
us:insert(100054)
assert( us:size() == 4 )

us:clear()
assert( us:size() == 0 )
assert( us:empty() )
