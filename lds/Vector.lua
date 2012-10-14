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
    $ *a;
    int alength;
    int n;
    size_t ct_size;
}
]]


local function VectorT__resize( v, reserve_n )
    local blength = math.max( 1, reserve_n or (2 * v.n) )
    if v.alength >= blength then return end

    local b = ffi.cast( v.a, C.malloc( blength * v.ct_size ) )
    ffi.copy( b, v.a, (v.n * v.ct_size) )
    C.free( v.a )
    v.a = b
    v.alength = blength
end 


local VectorT_mt = {

    __new = function( vt_ct, ct_size )
        return ffi.new( vt_ct, {
            a = C.malloc( 1 * ct_size ),
            alength = 1,
            n = 0,
            ct_size = ct_size,
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
            return math.floor( self.alength / self.ct_size )
        end,

        reserve = function( self, n )
            VectorT__resize( self, n )
        end,

        get = function( self, i )
            lds.assert( i >= 0 and i < self.alength, "get: index out of bounds" )
            return self.a[i]
        end,

        set = function( self, i, x )
            lds.assert( i >= 0 and i < self.alength, "set: index out of bounds" )
            local y = self.a[i]
            self.a[i] = x
            return y
        end,

        clear = function(self)
            self.n = 0
            C.free( self.a )
            self.a = C.malloc( 1 * self.ct_size )
            self.alength = 1
        end,

        insert = function( self, i, x )
            if type(x) == 'nil' then self:push_back(i) end  -- handle default index like table.insert
            lds.assert( i >= 0 and i <= self.alength, "insert: index out of bounds" )
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
            lds.assert( i >= 0 and i < self.alength, "remove: index out of bounds" )
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

    local vt = ffi.typeof( VectorT_cdef, ct )
    local vt_m = ffi.metatype( vt, VectorT_mt )
    return function()
        return vt_m( ffi.sizeof(ct) )
    end
end


function lds.Vector( ct )
    return lds.VectorT( ct )()
end


-- Return the lds API
return lds
