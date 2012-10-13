--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Queue

TODO: documentation here

See ArrayStack at opendatastructures.org:
http://opendatastructures.org/ods-cpp/2_1_Fast_Stack_Operations_U.html

TODO: bounds check (return nil or error?)
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/init'

local  ffi = require 'ffi'
local C = ffi.C


local QueueT_cdef = [[
struct {
    $ *a;
    int alength;
    int j;
    int n;
    size_t ct_size;
}
]]


local function QueueT__resize( q, reserve_n )
    local blength = math.max( 1, reserve_n or (2 * q.n) )
    if q.alength >= blength then return end

    local b = ffi.cast( q.a, C.malloc( blength * q.ct_size ) )
    for k = 0, q.n do
        b[k] = q.a[(q.j + k) % q.alength]
    end
    C.free( q.a )
    q.a = b
    q.alength = blength
end


local QueueT_mt = {
    
    __new = function( qt_ct, ct_size )
        return ffi.new( qt_ct, {
            a = C.malloc( 1 * ct_size ),
            alength = 1,
            n = 0,
            j = 0,
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

        capacity = function( self )
            return math.floor( self.alength / self.ct_size )
        end,

        reserve = function( self, n )
            QueueT__resize( self, n )
        end,

        empty = function( self )
            return self.n == 0
        end,

        get_front = function( self )
            lds.assert( self.n ~= 0, "get_front: Queue is empty" )
            return self.a[self.j]
        end,

        get_back = function( self )
            lds.assert( self.n ~= 0, "get_back: Queue is empty" )
            local idx = (self.j + (self.n - 1)) % self.alength
            return self.a[idx]
        end,

        push_back = function( self, x )
            if self.n + 1 > self.alength then QueueT__resize(self) end
            self.a[(self.j+self.n) % self.alength] = x
            self.n = self.n + 1
            return true
        end, 

        pop_front = function( self )
            lds.assert( self.n ~= 0, "pop_front: Queue is empty" )
            local x = self.a[self.j]
            self.j = (self.j + 1) % self.alength
            self.n = self.n - 1
            if self.alength >= (3 * self.n) then QueueT__resize(self) end
            return x
        end,

        clear = function( self )
            self.n = 0
            self.j = 0
        end,
    },
}


function lds.QueueT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    local qt = ffi.typeof( QueueT_cdef, ct )
    local qt_m = ffi.metatype( qt, QueueT_mt )
    return function()
        return qt_m( ffi.sizeof( ct ) )
    end
end


function lds.Queue( ct )
    return lds.QueueT( ct )()
end


-- Return the lds API
return lds
