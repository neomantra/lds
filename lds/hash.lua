--[[
lds - LuaJIT Data Structures

Copyright (c) 2012 Evan Wies.  All righs reserved.
See the COPYRIGHT file for licensing.

hash functionality

--]]

local lds = require 'lds/init'

local bit = require 'bit'
local blshift, brshift, bxor =  bit.lshift, bit.rshift, bit.bxor

-- simple hash function
function lds.hash( x )
    return tonumber(x)
end


-- adpted from boost::hash_combine
-- http://svn.boost.org/svn/boost/trunk/boost/functional/hash/hash.hpp
function lds.hash_combine( seed, v )
    -- magic number explanation:
    -- http://stackoverflow.com/questions/4948780/magic-numbers-in-boosthash-combine
    local magic = 0x9e3779b9
    local h = lds.hash(v) + magic + blshift(seed, 6) + brshift(seed, 2)
    return bxor(seed, h)
end


-- Return the lds API
return lds
