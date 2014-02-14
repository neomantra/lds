--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

HashSet

A set implemented as a chained hash table, with an interface based on std::unordered_set.

TODO: documentation here

For complexity details of HashSet, see ChainedHashTable at opendatastructures.org:
http://opendatastructures.org/ods-cpp/5_1_Hashing_with_Chaining.html

TODO: bounds check (return nil or error?)
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/hash'
require 'lds/Vector'

local ffi = require 'ffi'
local C = ffi.C

local bit = require 'bit'
local blshift, brshift, bor, bxor = bit.lshift, bit.rshift, bit.bor, bit.bxor


local HashSetT_cdef = [[
struct {
    $   *t; // lds.Vector<ct>
    int tlength;
    int n;
    int d;
    int z;
}
]]


local function HashSetT__hash( ust, x )
    local HashSetT__w = 32
    return brshift(
        (ust.z * lds.hash(x)),
        (HashSetT__w - ust.d) )
end


local function HashSetT__resize( ust )
    ust.d = 1
    while blshift(1, ust.d) <= ust.n do ust.d = ust.d + 1 end
    local shift_d = blshift( 1, ust.d )
    if shift_d == ust.tlength then return end  -- don't need to resize

    local newTable = ffi.cast( ust.t, C.malloc( ust._vt_size * shift_d ) )
    for i = 0, shift_d-1 do
        -- TODO: there has to be a better way
        local nti = newTable[i]
        nti.a = C.malloc( 1 * ust._ct_size )
        nti.alength = 1
        nti.n = 0
    end

    for i = 0, ust.tlength-1 do
        for j = 0, ust.t[i]:size()-1 do
            local k = ust.t[i]:get(j)
            local h = HashSetT__hash(ust, k)
            newTable[h]:push_back(k)
        end
        -- TODO: figure out better way
        C.free( ust.t[i].a )
    end
    C.free( ust.t )

    ust.t = newTable
    ust.tlength = shift_d
end


local HashSetT_mt = {
    
    __new = function( ust )
        local us = ffi.new( ust, {
            t = C.malloc( 2 * ust._vt_size ),
            tlength = 2,
            n = 0,
            d = 1,
            z = bor(math.random(lds.INT_MAX), 1),  -- 1 is a random odd integer
        })
        -- TODO: figure out better way
        for i = 0, 1 do
            us.t[i].a = C.malloc( 1 * ust._ct_size )
            us.t[i].alength = 1
            us.t[i].n = 0
        end
        return us
    end,

    __gc = function( self )
        -- TODO: figure out better way
        for i = 0, self.tlength-1 do
            C.free( self.t[i].a )
        end
        C.free( self.t )
    end,

    __len = function( self )
        return self.n
    end,

    __index = {

        size = function( self )
            return self.n
        end,

        empty = function( self )
            return self.n == 0
        end,

        insert = function( self, k )
            if self:find(k) ~= nil then return false end
            if (self.n + 1) > self.t:size() then HashSetT__resize(self) end
            local j = HashSetT__hash(self, k) 
            self.t[j]:push_back(k)
            self.n = self.n + 1
            return true
        end,

        remove = function( self, k )
            local j = HashSetT__hash(self, k)
            local list = self.t[j]
            local i = 0
            while i < list:size() do
                local y = list:get( i )
                if k == y then
                    list:erase( i )
                    self.n = self.n - 1
                    return y
                end
                i = i + 1
            end
            return nil
        end,

        find = function( self, k )
            local j = HashSetT__hash(self, k)
            local list = self.t[j]
            local i = 0
            while i < list:size() do
                local val = list:get(i)
                if k == val then return val end
                i = i + 1
            end
            return nil
        end,

        clear = function( self )
            self.n = 0
            HashSetT__resize( self )
        end,
    },
}


function lds.HashSetT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    local vt = lds.VectorT( ct )
    local ust = ffi.typeof( HashSetT_cdef, vt )

    -- clone the metatable and insert type-specific data
    local ust_mt = lds.simple_deep_copy(HashSetT_mt)
    ust_mt.__index._ct = ct
    ust_mt.__index._ct_size = ffi.sizeof(ct)
    ust_mt.__index._vt = vt
    ust_mt.__index._vt_size = ffi.sizeof(vt)

    return ffi.metatype( ust, ust_mt )
end


function lds.HashSet( ct )
    return lds.HashSetT( ct )()
end


-- Return the lds API
return lds
