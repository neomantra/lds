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
TODO: optimize push_front, push_back, pop_front, pop_back
TODO: allocator
TODO: iterator
TODO: full __index and __newindex?

--]]

local lds = require 'lds/init'

local  ffi = require 'ffi'
local C = ffi.C


local DequeT_cdef = [[
struct {
    $   *a;
    int alength;
    int j;
    int n;
}
]]


local function DequeT__resize( d, reserve_n )
    local blength = math.max( 1, reserve_n or (2 * d.n) )
    local b = ffi.cast( d.a, C.malloc( blength * d._ct_size ) )
    local k = 0
    while k < d.n do
        local idx = (d.j + k) % d.alength
        b[k] = d.a[idx]
        k = k + 1
    end
    C.free( d.a )
    d.a = b
    d.alength = blength
end


local DequeT_mt = {

    __new = function( dt )
        return ffi.new( dt, {
            a = C.malloc( 1 * dt._ct_size ),
            alength = 1,
            n = 0,
            j = 0,
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

        get = function( self, i )
            lds.assert( i >= 0 and i < self.alength, "get: index out of bounds" )
            local idx = (self.j + i) % self.alength
            return self.a[idx]
        end,

        get_front = function( self )
            lds.assert( self.n ~= 0, "get_front: Deque is empty" )
            return self:get(0)
        end,

        get_back = function( self )
            lds.assert( self.n ~= 0, "get_back: Deque is empty" )
            return self:get(self.n - 1)
        end,

        set = function( self, i, x )
            lds.assert( i >= 0 and i < self.alength, "set: index out of bounds" )
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
            DequeT__resize( self )
        end,

        insert = function( self, i, x )
            if type(x) == 'nil' then self:push_back(i) end  -- handle default index like table.insert
            lds.assert( i >= 0 and i <= self.alength, "insert: index out of bounds" )

            if (self.n + 1) > self.alength then DequeT__resize(self) end
            if i < (self.n / 2) then  -- shift a[0],..,a[i-1] left one position
                self.j = (self.j == 0) and (self.alength - 1) or (self.j - 1)
                local k = 0
                while k <= (i - 1) do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k + 1) % self.alength
                    self.a[idx] = a[idx1]
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
            if type(i) == 'nil' then return self:pop_back() end  -- handle default index like table.remove
            lds.assert( i >= 0 and i < self.alength, "remove: index out of bounds" )

            local x = self.a[(self.j + i) % self.alength]
            if i < (self.n / 2) then  -- shift a[0],..,[i-1] right one position
                local k = i
                while k > 0 do
                    local idx  = (self.j + k    ) % self.alength
                    local idx1 = (self.j + k - 1) % self.alength
                    a[idx] = a[idx1]
                    k = k - 1
                end
                self.j = (self.j + 1) % self.alength
            else  -- shift a[i+1],..,a[n-1] left one position
                local k = i
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

        push_front = function( self, x )
            return self:insert( 0, x )
        end,

        push_back = function( self, x )
            return self:insert( self.n, x )
        end,

        pop_front = function( self )
            return self:erase( 0 )
        end,

        pop_back = function( self )
            return self:erase( self.n - 1 )
        end,
    }, 
}


function lds.DequeT( ct )
    if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

    -- clone the metatable and insert type-specific data
    local dt_mt = lds.simple_deep_copy(DequeT_mt)
    dt_mt.__index._ct = ct
    dt_mt.__index._ct_size = ffi.sizeof(ct)

    local dt = ffi.typeof( DequeT_cdef, ct )
    return ffi.metatype( dt, dt_mt )
end


function lds.Deque( ct )
    return lds.DequeT( ct )()
end


-- Return the lds API
return lds
