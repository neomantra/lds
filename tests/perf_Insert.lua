-- Test insertion rate of various containers.
--
-- To run:
--    luajit tests/perf_Insert.lua NUMBER_OF_INSERTS
--

-- config
if #arg > 1 then
    print('usage:  per_Insert.lua num_inserts')
    os.exit(-1)
end

local NUMBER_OF_INSERTS = arg[1] and tonumber(arg[1]) or 1e6


-- run
local ffi = require 'ffi'
local C = ffi.C

local lds = require 'lds/HashMap'
require 'lds/HashSet'

ffi.cdef("int rand(void);");
local os_clock = os.clock
local random = math.random

local function benchmark( name, fn )
    io.stdout:write(string.format( '%15s... ', name ) )
    io.stdout:flush()
    collectgarbage()
    local start_time = os_clock()
    fn()
    local end_time = os_clock()
    collectgarbage()
    local collect_time = os_clock()
    io.stdout:write(string.format('run:%0.3f  collect:%0.3f  num:%d\n',
        end_time - start_time, collect_time - end_time, NUMBER_OF_INSERTS))
end


ffi.cdef([[
struct Point4 {
    double x, y, z, w;
};
]])
local Point4_t = ffi.typeof('struct Point4')

local double_t = ffi.typeof('double')
local int32_t = ffi.typeof('int32_t')
local uint64_t = ffi.typeof('uint64_t')

local function Point4_random()
    return Point4_t( double_t(C.rand()), double_t(C.rand()), double_t(C.rand()), double_t(C.rand()) )
end

-- [[
benchmark( 'copy random to ffi struct', function()
    local dest = ffi.typeof('struct{ int32_t k; struct Point4 v; }')()
    for i = 0, NUMBER_OF_INSERTS do
        dest.k = C.rand()
        dest.v = Point4_random()
    end
end)

benchmark( 'copy random Lua array to a local', function()
    for i = 0, NUMBER_OF_INSERTS do
        local x = { C.rand(), C.rand(), C.rand(), C.rand() }
    end
end)

if NUMBER_OF_INSERTS < 1e7 then -- LuaJIT runs outs of memory
    benchmark( 'insert random into Lua table', function()
        local point_table = {}
        for i = 0, NUMBER_OF_INSERTS do
            point_table[C.rand()] = Point4_random()
        end
    end)
else
    io.stdout:write('insert random into Lua table... skipping due to memory constraints\n')
end

benchmark( 'insert random into Vector', function()
    local point_vec = lds.Vector( Point4_t )
    for i = 0, NUMBER_OF_INSERTS do
        point_vec:push_back( Point4_random() )
    end
end)

benchmark( 'insert random into HashSet', function()
    local point_map = lds.HashSet( double_t )
    for i = 0, NUMBER_OF_INSERTS do
        point_map:insert( C.rand() )
    end
end)
--]]
benchmark( 'insert random into HashMap', function()
    local point_map = lds.HashMap( int32_t, Point4_t )
    for i = 0, NUMBER_OF_INSERTS do
        point_map:insert( C.rand(), Point4_random() )
    end
end)
