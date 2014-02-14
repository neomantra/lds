--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

HashMap

A map implemented as a chained hash table, with an interface based on std::unordered_map.

TODO: documentation here

For complexity details of HashMap, see ChainedHashTable at opendatastructures.org:
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


local PairT_cdef = [[
struct {
    $ key;
    $ val;
}
]]


local HashMapT_cdef = [[
struct {
    $   *t; // lds.Vector<PairT>
    int tlength;
    int n;
    int d;
    int z;
}
]]


local function HashMapT__hash( ust, x )
    local HashMapT__w = 32
    return brshift(
        (ust.z * lds.hash(x)),
        (HashMapT__w - ust.d) )
end


local function HashMapT__resize( ust )
    ust.d = 1
    while blshift(1, ust.d) <= ust.n do ust.d = ust.d + 1 end
    local shift_d = blshift( 1, ust.d )
    if shift_d == ust.tlength then return end  -- don't need to resize

    local newTable = ffi.cast( ust.t, C.malloc( ust._vt_size * shift_d ) )
    for i = 0, shift_d-1 do
        -- TODO: there has to be a better way
        local nti = newTable[i]
        nti.a = C.malloc( 1 * ust._pt_size )
        nti.alength = 1
        nti.n = 0
    end

    for i = 0, ust.tlength-1 do
        for j = 0, ust.t[i]:size()-1 do
            local pair = ust.t[i]:get(j)
            local h = HashMapT__hash(ust, pair.key)
            newTable[h]:push_back(pair)
        end
        -- TODO: figure out better way
        C.free( ust.t[i].a )
    end
    C.free( ust.t )

    ust.t = newTable
    ust.tlength = shift_d
end


local HashMapT_mt = {
    
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
            us.t[i].a = C.malloc( 1 * ust._pt_size )
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

        insert = function( self, k, v )
            local pair = self:find( k )
            if pair then
                local old_val = pair.val
                pair.val = v
                return old_val
            end

            if (self.n + 1) > self.t:size() then HashMapT__resize(self) end
            local j = HashMapT__hash(self, k) 
            -- initialization of nested structs are not compiled,
            -- so we use a pre-allocated placeholder, `_pt_scratch`, stored in the metatable
            -- otherwise, this would just be: self.t[j]:push_back(self._pt(k, v))
            local pt = self._pt_scratch
            pt.key, pt.val = k, v
            self.t[j]:push_back(pt)
            self.n = self.n + 1
            return true
        end,

        remove = function( self, k )
            local j = HashMapT__hash(self, k)
            local list = self.t[j]
            local i = 0
            while i < list:size() do
                local y = list:get( i )
                if k == y.key then
                    list:erase( i )
                    self.n = self.n - 1
                    return y.val
                end
                i = i + 1
            end
            return nil
        end,

        find = function( self, k )
            local j = HashMapT__hash(self, k)
            local list = self.t[j]
            local i = 0
            while i < list:size() do
                local pair = list:get(i)
                if k == pair.key then return pair end
                i = i + 1
            end
            return nil
        end,

        clear = function( self )
            self.n = 0
            HashMapT__resize( self )
        end,
    },
}


function lds.HashMapT( ct_key, ct_val )
    if type(ct_key) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end
    if type(ct_val) ~= 'cdata' then error("argument 2 is not a valid 'cdata'") end

    local pt = ffi.typeof( PairT_cdef, ct_key, ct_val )
    local vt = lds.VectorT( pt )
    local umt = ffi.typeof( HashMapT_cdef, vt )

    -- clone the metatable and insert type-specific data
    local umt_mt = lds.simple_deep_copy(HashMapT_mt)
    umt_mt.__index._ct_key = ct_key
    umt_mt.__index._ct_val = ct_val
    umt_mt.__index._pt = pt
    umt_mt.__index._pt_size = ffi.sizeof(pt)
    umt_mt.__index._vt = vt
    umt_mt.__index._vt_size = ffi.sizeof(vt)
    umt_mt.__index._pt_scratch = pt()  -- pre-allocated PairT

    return ffi.metatype( umt, umt_mt )
end


function lds.HashMap( ct_key, ct_val )
    return lds.HashMapT( ct_key, ct_val )()
end


-- Return the lds API
return lds
