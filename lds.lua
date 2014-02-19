--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

Common module require for convenience.

Individual data structures may be require'd instead, for example:
local lds = require 'lds/Vector'
--]]

local lds = require 'lds/Array'
require 'lds/Vector'
require 'lds/HashMap'

return lds
