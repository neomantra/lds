--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Exercises lds.Queue
--]]

local ffi = require 'ffi'
local lds = require 'lds/Queue'

local double_t = ffi.typeof('double')

local dq_t = lds.QueueT( double_t )

local dq = dq_t()

assert( #dq == 0 )
assert( dq:size() == 0 )
assert( dq:empty() )

dq:push_back( 10 )
assert( #dq == 1 )
assert( dq:size() == 1 )
assert( dq:get_front() == 10 )
assert( dq:get_back() == 10 )

assert( dq:pop_front() == 10 )
assert( #dq == 0 )
assert( dq:size() == 0 )
assert( dq:empty() )

dq:push_back( 10 )
dq:push_back( 11 )
dq:push_back( 12 )
assert( dq:get_front() == 10 )
assert( dq:get_back() == 12 )

dq:clear()
assert( #dq == 0 )
assert( dq:size() == 0 )
assert( dq:empty() )
