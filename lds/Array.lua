--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Array

Note that this implementation does *not* use the FFI VLA.

TODO: bounds check (return nil or error?)
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/init'

local ffi = require 'ffi'
local C = ffi.C


local ArrayT_cdef = [[
struct {
    $   *a;
    int n_max;
}
]]


local ArrayT_mt = {

    __new = function( at, n_max )
        return ffi.new( at, {
            a = C.malloc( n_max * at._ct_size ),
            n_max = n_max,
        })
    end,

    __gc = function( self )
        C.free( self.a )
    end,

    __len = function( self )
        return self.n_max
    end,

    __index = {

        size = function( self )
            return self.n_max
        end,

        empty = function( self )
            return self.n_max == 0
        end,

        get = function( self, i )
            lds.assert( i >= 0 and i < self.n_max, "get: index out of bounds" )
            return self.a[i]
        end,

        set = function( self, i, x )
            lds.assert( i >= 0 and i < self.n_max, "set: index out of bounds" )
            local y = self.a[i]
            self.a[i] = x
            return y
        end,
    },
}


function lds.ArrayT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    -- clone the metatable and insert type-specific data
    local at_mt = {}
    for k, v in pairs(ArrayT_mt) do at_mt[k] = v end
    at_mt.__index._ct = ct
    at_mt.__index._ct_size = ffi.sizeof(ct)

    local at = ffi.typeof( ArrayT_cdef, ct )
    return ffi.metatype( at, at_mt )
end


function lds.Array( ct, n_max )
    return lds.ArrayT( ct )( n_max )
end


-- Return the lds API
return lds
