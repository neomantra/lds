--[[
lds - LuaJIT Data Structures

@copyright Copyright (c) 2012-2014 Evan Wies.  All rights reserved.
@license MIT License, see the COPYRIGHT file.

@module allocator

allocator_interface = {
    allocate   = function(self, n)     -- allocates storage of n elements
    deallocate = function(self, p)     -- deallocates storage using the allocator
    reallocate = function(self, p, n)  -- reallocates storage at p to n elements
}

MallocAllocator    uses the standard C malloc/free
VLAAllocator       uses FFI VLAs and hence the LuaJIT allocator
JemallocAllocator  uses jemalloc (if available)


--]]

local lds = require 'lds/init'

local ffi = require 'ffi'
local C = ffi.C


-------------------------------------------------------------------------------
-- MallocAllocator
--
-- An lds allocator that uses the standard C malloc/free
--

ffi.cdef([[
void * malloc(size_t size); 
void * calloc(size_t count, size_t size);
void * valloc(size_t size); 
void * realloc(void *ptr, size_t size);
void free(void *ptr); 
]])


local MallocAllocatorT__mt = {
    __index = {
        -- may be re-assigned in MallocAllocatorT
        allocate  = function(self, n)
            return C.calloc( n, self._ct_size )
        end,
        deallocate = function(self, p)
            if p ~= 0 then C.free(p) end
        end,
        reallocate = function(self, p, n)
            return C.realloc(p, n)
        end,
    }
}

-- which is 'malloc', 'calloc' (zeroed), or 'valloc' (page-aligned)
-- calloc is the default to be consistent with LuaJIT's zero-ing behavior
function lds.MallocAllocatorT( ct, which )
    if type(ct) ~= 'cdata' then error('argument 1 is not a valid "cdata"') end

    -- clone the metatable and insert type-specific data
    local t_mt = lds.simple_deep_copy(MallocAllocatorT__mt)
    t_mt.__index._ct = ct
    t_mt.__index._ct_size = ffi.sizeof(ct)

    if which == nil or which == 'calloc' then
        -- keep default
    elseif which == 'malloc' then        
        t_mt.__index.allocate = function(self, n)
            return C.malloc( n * self._ct_size )
        end
    elseif which == 'valloc' then
        t_mt.__index.allocate = function(self, n)
            return C.malloc( n * self._ct_size )
        end
    else
        error('argument 2 must be nil, "calloc", "malloc", or "valloc"')
    end

    local t_anonymous = ffi.typeof( 'struct {}' )
    return ffi.metatype( t_anonymous, t_mt )
end


-- which is 'malloc', 'calloc' (zeroed), or 'valloc' (page-aligned)
-- calloc is the default to be consistent with LuaJIT's zero-ing behavior
function lds.MallocAllocator( ct, which )
    return lds.MallocAllocatorT( ct, which )()
end



-------------------------------------------------------------------------------
-- VLAAllocator
--
-- An lds allocator that uses FFI VLAs and hence the LuaJIT allocator
--
-- Note that there is some extra bookkeeping required by the allocator.
-- of one 32-character string per allocated object.
--
-- This allocator also does not support a true realloc, but rather does
-- a new and copy.
--


-- Anchor for VLA objects used by all VLAAllocators
--
-- Since e are returning raw pointers, we need to keep the VLA cdata from
-- being garbage collected.  So we convert the address to a size_t and then
-- to a string, and use that as a key for the VLA cdata.
local VLAAllocator__anchors = {}


VLAAllocatorT__mt = {
    __index = {
        allocate  = function(self, n)
            local vla = ffi.new( self._vla, n )
            VLAAllocator__anchors[tostring(ffi.cast(lds.size_t, vla._data))] = vla
            return vla._data
        end, 
        deallocate = function(self, p)
            -- remove the stored reference and then let GC do the rest
            if p ~= nil then
                VLAAllocator__anchors[tostring(ffi.cast(lds.size_t, p))] = nil
            end
        end,
        reallocate = function(self, p, n)
            if p == nil then
                local vla = ffi.new( self._vla, n )
                VLAAllocator__anchors[tostring(ffi.cast(lds.size_t, vla._data))] = vla
                return vla._data
            else
                local key_old = tostring(ffi.cast(lds.size_t, p))
                local vla_old = VLAAllocator__anchors[key_old]

                local vla_new = ffi.new( self._vla, n )
                local key_new = tostring(ffi.cast(lds.size_t, vla_new._data))

                VLAAllocator__anchors[key_new] = vla_new
                ffi.copy(vla_new._data, p, ffi.sizeof(vla_old))
                VLAAllocator__anchors[key_old] = nil
                return vla_new._data
            end
        end,
    }
}


function lds.VLAAllocatorT( ct )
    if type(ct) ~= 'cdata' then error('argument 1 is not a valid "cdata"') end

    -- clone the metatable and insert type-specific data
    local t_mt = lds.simple_deep_copy(VLAAllocatorT__mt)
    t_mt.__index._ct = ct
    t_mt.__index._ct_size = ffi.sizeof(ct)
    t_mt.__index._vla = ffi.typeof( 'struct { $ _data[?]; }', ct )
    
    local t_anonymous = ffi.typeof( 'struct {}' )
    return ffi.metatype( t_anonymous, t_mt )
end


function lds.VLAAllocator( ct )
    return lds.VLAAllocatorT( ct )()
end


-------------------------------------------------------------------------------
-- JemallocAllocator
--
-- An lds allocator that uses jemalloc, if available.
--

-- check for jemalloc
local success, J =  pcall(function() return require 'lds/jemalloc' end)

if success and J then

    lds.J = J  -- make jemalloc lib immediately available to clients

    local JemallocAllocatorT__mt = {
        __index = {
            allocate  = function(self, n)
                return J.mallocx( n * self._ct_size, self._flags )
            end,
            deallocate = function(self, p)
                if p ~= nil then J.dallocx(p, self._flags) end
            end,
            reallocate = function(self, p, n)
                if p == nil then
                    return J.mallocx( n * self._ct_size, self._flags )
                else
                    return J.rallocx(p, n, self._flags)
                end
            end,
        }
    }

    -- if flags is not specified, J.MALLOCX_ZERO is the default to be
    -- consistent with LuaJIT's allocation behavior
    function lds.JemallocAllocatorT( ct, flags )
        if type(ct) ~= 'cdata' then error("argument 1 is not a valid 'cdata'") end

        -- clone the metatable and insert type-specific data
        local t_mt = lds.simple_deep_copy(JemallocAllocatorT__mt)
        t_mt.__index._ct = ct
        t_mt.__index._ct_size = ffi.sizeof(ct)
        t_mt.__index._flags = flags or J.MALLOCX_ZERO()

        local t_anonymous = ffi.typeof( "struct {}" )
        return ffi.metatype( t_anonymous, t_mt )
    end


    -- if flags is not specified, J.MALLOCX_ZERO is the default to be
    -- consistent with LuaJIT's allocation behavior
    function lds.JemallocAllocator( ct, flags )
        return lds.JemallocAllocatorT( ct, flags )()
    end

end -- was jemalloc required?


-- Return the lds API
return lds
