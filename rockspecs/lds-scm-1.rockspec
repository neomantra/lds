package = 'lds'
version = 'scm-1'
source = {
    url = 'git://github.com/neomantra/lds.git',
    branch = 'master',
}
description = {
    summary = 'LuaJIT Data Structures',
    detailed = 'LuaJIT Data Structures -- hold cdata in Arrays, Vectors, and HashMaps',
    homepage = 'https://github.com/neomantra/lds',
    license = 'MIT',
}
dependencies = {
    -- TODO: specify luajit >= 2.0
}
build = {
    type = 'none',
    install = {
        lua = {
            ['lds']           = 'lds.lua',
            ['lds.allocator'] = 'lds/allocator.lua',
            ['lds.Array']     = 'lds/Array.lua',
            ['lds.hash']      = 'lds/hash.lua',
            ['lds.HashMap']   = 'lds/HashMap.lua',
            ['lds.init']      = 'lds/init.lua',
            ['lds.jemalloc']  = 'lds/jemalloc.lua',
            ['lds.Vector']    = 'lds/Vector.lua',
        },
    },
}
