--[[
lds - LuaJIT Data Structures

Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
MIT License, see the COPYRIGHT file.

Exercises lds.Array
--]]

local ffi = require 'ffi'
local lds = require 'lds.Array'
require 'lds.allocator'

local double_t = ffi.typeof('double')

for _, ct in pairs{ lds.uint32_t, double_t, lds.size_t } do
    for _, alloc in pairs{ lds.MallocAllocator,
                           lds.VLAAllocator,
                           lds.JemallocAllocator,
                         } do
        local a_t = lds.ArrayT( ct, alloc )

        local a = a_t( 10 )

        assert( #a == 10 )
        assert( a:size() == 10 )
        assert( not a:empty() )

        assert( a:get(0) == 0 )

        assert( a:set(3, 5) == 0 )
        assert( a:get(3) == 5 )
    end
end
