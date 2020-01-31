--[[
lds - LuaJIT Data Structures

Copyright (c) 2012-2020 Evan Wies.  All rights reserved.
MIT License, see the COPYRIGHT file.

Exercises lds.Vector
--]]

local ffi = require 'ffi'
local lds = require 'lds.Vector'
require 'lds.allocator'

local double_t = ffi.typeof('double')

for _, ct in pairs{ lds.uint32_t, double_t, lds.size_t } do
    for _, alloc in pairs{ lds.MallocAllocator,
                           lds.VLAAllocator,
                           lds.JemallocAllocator,
                         } do
        local dv_t = lds.VectorT( ct, alloc )

        local v = dv_t()

        assert( #v == 0 )
        assert( v:size() == 0 )
        assert( v:empty() )
        assert( v:get(1) == nil )
        assert( v:front() == nil )
        assert( v:back() == nil )

        v:insert( 0, 6 )
        assert( #v == 1 )
        assert( v:size() == 1 )
        assert( v:get(0) == 6 )
        assert( v:get(0) == 6 )
        assert( v:front() == 6 )
        assert( v:back() == 6 )

        v:insert( 0, 5 )
        assert( #v == 2 )
        assert( v:size() == 2 )
        assert( v:get(0) == 5 )
        assert( v:get(1) == 6 )
        assert( v:front() == 5 )
        assert( v:back() == 6 )

        assert( v:set(1, 7) == 6 )
        assert( v:get(1) == 7 )
        assert( v:front() == 5 )
        assert( v:back() == 7 )

        assert( v:erase(0) == 5 )
        assert( #v == 1 )
        assert( v:size() == 1 )
        assert( v:get(0) == 7 )
        assert( v:front() == 7 )
        assert( v:back() == 7 )

        v:insert( 0, 5 )
        v:insert( 0, 5 )
        v:clear()
        assert( #v == 0 )
        assert( v:size() == 0 )
        assert( v:empty() )
        assert( v:front() == nil )
        assert( v:back() == nil )

        v:push_back( 2 )
        assert( #v == 1 )
        assert( v:size() == 1 )
        assert( v:get(0) == 2 )

        assert( v:pop_back() == 2 )
        assert( #v == 0 )
        assert( v:size() == 0 )

        v:shrink_to_fit()
    end
end
