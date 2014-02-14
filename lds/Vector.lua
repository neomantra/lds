--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Vector

TODO: documentation here

For complexity details of Vector, see ArrayStack at opendatastructures.org:
http://opendatastructures.org/ods-cpp/2_1_Fast_Stack_Operations_U.html

TODO: bounds check (return nil or error?)
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/init'

local ffi = require 'ffi'
local C = ffi.C


local VectorT_cdef = [[
struct {
    $   *a;
    int alength;
    int n;
}
]]


local function VectorT__resize( v, reserve_n )
    local blength = math.max( 1, reserve_n or (2 * v.n) )
    if v.alength >= blength then return end

    local b = ffi.cast( v.a, C.malloc( blength * v._ct_size ) )
    ffi.copy( b, v.a, (v.n * v._ct_size) )
    C.free( v.a )
    v.a = b
    v.alength = blength
end 


local VectorT_mt = {

    __new = function( vt )
        return ffi.new( vt, {
            a = C.malloc( 1 * vt._ct_size ),
            alength = 1,
            n = 0,
        })
    end,

    __gc = function( self )
        C.free( self.a )
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

        capacity = function( self )
            return math.floor( self.alength / self._ct_size )
        end,

        reserve = function( self, n )
            VectorT__resize( self, n )
        end,

        get = function( self, i )
            if i < 0 or i >= self.alength then error("get: index out of bounds") end
            return self.a[i]
        end,

        set = function( self, i, x )
            if i < 0 or i >= self.alength then error("set: index out of bounds") end
            local y = self.a[i]
            self.a[i] = x
            return y
        end,

        clear = function(self)
            self.n = 0
            VectorT__resize( self )
        end,

        insert = function( self, i, x )
            if type(x) == 'nil' then self:push_back(i) end  -- handle default index like table.insert
            if i < 0 or i > self.alength then error("insert: index out of bounds") end
            if self.n + 1 > self.alength then VectorT__resize(self) end
            local j = self.n
            while j > i do
                self.a[j] = self.a[j - 1]
                j = j - 1
            end
            self.a[i] = x
            self.n = self.n + 1
        end,

        erase = function( self, i )
            if type(i) == 'nil' then return self:pop_back() end  -- handle default index like table.remove
            if i < 0 or i >= self.alength then error("remove: index out of bounds") end
            local x = self.a[i]
            local j = i
            while j < (self.n - 1) do
                self.a[j] = self.a[j + 1]
                j = j + 1
            end
            self.n = self.n - 1
            if self.alength >= (3 * self.n) then VectorT__resize(self) end
            return x
        end,

        push_back = function( self, x )
            if self.n + 1 > self.alength then VectorT__resize(self) end
            self.a[self.n] = x
            self.n = self.n + 1
        end,

        pop_back = function( self )
            local x = self.a[self.n - 1]
            self.n = self.n - 1
            if self.alength >= (3 * self.n) then VectorT__resize(self) end
            return x
        end,
    },
}


function lds.VectorT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    -- clone the metatable and insert type-specific data
    local vt_mt = lds.simple_deep_copy(VectorT_mt)
    vt_mt.__index._ct = ct
    vt_mt.__index._ct_size = ffi.sizeof(ct)

    local vt = ffi.typeof( VectorT_cdef, ct )
    return ffi.metatype( vt, vt_mt )
end


function lds.Vector( ct )
    return lds.VectorT( ct )()
end


-- Return the lds API
return lds
