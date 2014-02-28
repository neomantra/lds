--[[
lds - LuaJIT Data Structures

Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
MIT License, see the COPYRIGHT file.

Exercises lds.HashMap
--]]

local ffi = require 'ffi'
local lds = require 'lds/HashMap'

local int_t = ffi.typeof('int')
local double_t = ffi.typeof('double')

for _, alloc in pairs{ lds.MallocAllocator,
                       lds.VLAAllocator,
                       lds.JemallocAllocator,
                     } do
    local hm_t = lds.HashMapT( int_t, double_t, alloc )  -- map from int to double
    local hm = hm_t()

    assert( #hm == 0 )
    assert( hm:size() == 0 )
    assert( hm:empty() )

    assert( hm:insert(5, 24.0) == true)
    assert( #hm == 1 )
    assert( hm:size() == 1 )
    assert( not hm:empty() )

    assert( hm:find(5).key == 5 )
    assert( hm:find(5).val == 24.0 )
    assert( hm:insert(5, 22.0) == 24.0 )
    assert( hm:size() == 1 )

    assert( hm:remove(5) == 22.0 )
    assert( hm:remove(5) == nil )
    assert( hm:size() == 0 )

    hm:insert(5, 21.0)
    hm:insert(6, 22.0)
    hm:insert(7, 23.0)
    hm:insert(100054, 77.0)
    assert( hm:size() == 4 )
    assert( hm:find(5).val == 21.0 )
    assert( hm:find(6).val == 22.0 )
    assert( hm:find(7).val == 23.0 )
    assert( hm:find(100054).val == 77.0 )

    -- test iterator
    local keys, vals = {}, {}
    for pair in hm:iter() do
        keys[#keys+1], vals[#keys+1] = pair.key, pair.val
    end
    table.sort(keys) ; table.sort(vals)
    assert( #keys == 4 )
    assert( keys[1] == 5 )
    assert( keys[2] == 6 )
    assert( keys[3] == 7 )
    assert( keys[4] == 100054 )
    assert( #vals == 4 )
    assert( vals[1] == 21 )
    assert( vals[2] == 22 )
    assert( vals[3] == 23 )
    assert( vals[4] == 77 )

    hm:clear()
    assert( hm:size() == 0 )
    assert( hm:empty() )
end
