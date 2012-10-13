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

-- TODO: ok, so it "compiles"... exercise it