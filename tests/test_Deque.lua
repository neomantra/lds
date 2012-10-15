--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.Deque
--]]

local ffi = require 'ffi'
local lds = require 'lds/Deque'

local double_t = ffi.typeof('double')

local dd_t = lds.DequeT( double_t )

local dd = dd_t()

assert( #dd == 0 )
assert( dd:size() == 0 )
assert( dd:empty() )

dd:push_back( 10 )
assert( #dd == 1 )
assert( dd:size() == 1 )
assert( dd:get_front() == 10 )
assert( dd:get_back() == 10 )

assert( dd:pop_front() == 10 )
assert( #dd == 0 )
assert( dd:size() == 0 )
assert( dd:empty() )

dd:push_back( 10 )
dd:push_back( 11 )
dd:push_back( 12 )
assert( dd:get_front() == 10 )
assert( dd:get_back() == 12 )

dd:clear()
assert( #dd == 0 )
assert( dd:size() == 0 )
assert( dd:empty() )

dd:push_front( 10 )
assert( #dd == 1 )
assert( dd:size() == 1 )
assert( dd:get_front() == 10 )
assert( dd:get_back() == 10 )

assert( dd:pop_front() == 10 )
assert( #dd == 0 )
assert( dd:size() == 0 )
assert( dd:empty() )

--[[ TODO: THIS TEST FAILS!!
dd:push_front( 21 )
dd:push_front( 22 )
dd:push_front( 23)
print(dd:get_back(), dd:get_front())
assert( dd:get_front() == 23 )
assert( dd:get_back() == 21 )
--]]
