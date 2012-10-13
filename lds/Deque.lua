--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

Deque

NOTE: The interface might change a bit
TODO: documentation here

See DualArrayDeque at opendatastructures.org:
http://opendatastructures.org/ods-cpp/2_4_Fast_Deque_Operations_U.html

TODO: bounds check (return nil or error?)
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/init'

local  ffi = require 'ffi'
local C = ffi.C


local DequeT_cdef = [[
struct {
    $ *a;
    int alength;
    int j;
    int n;
    size_t ct_size;
}
]]


local function DequeT__resize( d, reserve_n )
    local blength = math.max( 1, reserve_n or (2 * d.n) )
    local b = ffi.cast( d.a, C.malloc( blength * d.ct_size ) )
    for k = 0, d.n do
        local idx = (d.j + k) % d.alength
        b[k] = d.a[idx]
    end
    C.free( d.a )
    d.a = b
    d.alength = blength
end


local DequeT_mt = {

    __new = function( dt_ct, ct_size )
        return ffi.new( dt_ct, {
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

        get = function( self, i )
            -- TODO: bounds check
            local idx = (self.j + i) % self.alength
            return self.a[idx]
        end,

        set = function( self, i, x )
            -- TODO: bounds check
            local idx = (self.j + i) % self.alength
            local y = self.a[idx]
            self.a[idx] = x
            return y
        end,

        reserve = function( self, n )
            DequeT__resize( self, n )
        end,

        clear = function( self )
            self.n = 0
            self.j = 0
            C.free( self.a )
            local b = ffi.cast( self.a, C.malloc( 1 * self.ct_size ) )
            self.a = b
            self.alength = 1
        end,

        insert = function( self, i, x )
            -- TODO: bounds check
            if self.n + 1 > self.alength then DequeT__resize(self) end
            if i < (self.n / 2) then  -- shift a[0],..,a[i-1] left one position
                self.j = (self.j == 0) and (self.alength - 1) or (self.j - 1)
                local k = 0
                while k <= (i - 1) do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k + 1) % self.alength
                    self.a[idx] = a[idx1];
                    k = k + 1
                end
            else  -- shift a[i],..,a[n-1] right one position
                local k = self.n
                while k > i do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k - 1) % self.alength
                    a[idx] = a[idx1]
                    k = k - 1
                end
            end
            local idx = (self.j + i) % self.alength 
            self.a[idx] = x
            self.n = self.n + 1
        end,

        erase = function( self, i )
            -- TODO: bounds check
            local x = self.a[(self.j + i) % self.alength]
            if i < (self.n / 2) then  -- shift a[0],..,[i-1] right one position
                local k = i
                while k > 0 do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k - 1) % self.alength
                    a[idx] = a[idx1]
                    k = k - 1
                end
                self.j = (self.j + 1) % self.alength;
            else  -- shift a[i+1],..,a[n-1] left one position
                while k < (self.n - 1) do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k + 1) % self.alength
                    self.a[idx] = self.a[idx1]
                    k = k + 1
                end
            end
            self.n = self.n - 1
            if (3 * self.n) < self.alength then DequeT__resize(self) end
            return x
        end,

        -- TODO: push_back, push_front, pop_back, pop_front
    }, 
}


function lds.DequeT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    local dt = ffi.typeof( DequeT_cdef, ct )
    local dt_m = ffi.metatype( dt, DequeT_mt )
    return function()
        return dt_m( ffi.sizeof( ct ) )
    end
end


function lds.Deque( ct )
    return lds.DequeT( ct )()
end


-- Return the lds API
return lds
