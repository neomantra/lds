-------------------------------------------------------------------------------
-- LuaJIT bindings to the jemalloc library
--
-- Copyright (c) 2014 Evan Wies.
-- Released under the MIT license.  See the LICENSE file.
--
-- Project home: https://github.com/neomantra/luajit-jemalloc
--
-- Does not load jemalloc, this must be done explicitly by the client
-- either with ffi.load or through a preload mechanism.
--
-- Only binds the 'non-standard API'
-- Adheres to API version 3.5.0
--


-- jemalloc uses an optional copmile-time prefix.
-- users must determine the prefix and assign it either to the global
-- variable JEMALLOC_PREFIX (set prior to the first `require` of this library),
-- or set the environment variable JEMALLOC_PREFIX.
-- Defaults to no prefix.
local JEMALLOC_PREFIX = JEMALLOC_PREFIX or os.getenv('JEMALLOC_PREFIX') or ''

local ffi = require 'ffi'
local C = ffi.C

do
    local cdef_template = [[
int !_!mallctl(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
void *!_!mallocx(size_t size, int flags);
void *!_!rallocx(void *ptr, size_t size, int flags);
size_t !_!xallocx(void *ptr, size_t size, size_t extra, int flags);
size_t !_!sallocx(void *ptr, int flags);
void !_!dallocx(void *ptr, int flags);
size_t !_!nallocx(size_t size, int flags);
int !_!mallctl(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
int !_!mallctlnametomib(const char *name, size_t *mibp, size_t *miblenp);
int !_!mallctlbymib(const size_t *mib, size_t miblen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
void !_!malloc_stats_print(void (*write_cb) (void *, const char *), void *cbopaque, const char *opts);
size_t !_!malloc_usable_size(const void *ptr);

int ffs(int i);
]]
    local cdef_str = string.gsub(cdef_template, '!_!', JEMALLOC_PREFIX)
    ffi.cdef(cdef_str)
end


-- check if it jemalloc was pre-loaded
do
    local mallctl_fname = JEMALLOC_PREFIX..'mallctl'
    if not pcall(function() return C[mallctl_fname] end) then
        error('jemalloc library was not pre-loaded or the prefix "'..JEMALLOC_PREFIX..'" is incorrect')
    end
end

-- our public API
local J = {}

do
    local abi_os = ffi.os:lower()
    if abi_os == 'linux' then
        J.EINVAL, J.ENOENT, J.EPERM, J.EFAULT, J.EAGAIN = 22, 2, 1, 14, 11
    elseif abi_os == 'osx' then
        J.EINVAL, J.ENOENT, J.EPERM, J.EFAULT, J.EAGAIN = 22, 2, 1, 14, 35
    elseif abi_os == 'bsd' then
        J.EINVAL, J.ENOENT, J.EPERM, J.EFAULT, J.EAGAIN = 22, 2, 1, 14, 35 
    else
        error('unsupported OS: '..abi_os)
    end
end


-------------------------------------------------------------------------------
-- malloctl support
--
-- First implement mallocctl_read, since we need to
-- check that we have the correct library version
--

do
    -- all the mallctl entries can share these holders
    -- since they are not accessed simultaneously and only
    -- used duing the mallctl invocation
    local bool_1   = ffi.new('bool[1]')
    local uint64_1 = ffi.new('uint64_t[1]')
    local ksz_1    = ffi.new('const char*[1]')
    local size_1   = ffi.new('size_t[1]')
    local ssize_1  = ffi.new('long[1]') -- TODO: is this correct in all circumstances?

    local mallctl_params = {
        -- param                 = { holder,   read?, write? }
       ['version']               = { ksz_1,    true,  false },
       ['epoch']                 = { uint64_1, true,  true  },
       ['config.debug']          = { bool_1,   true,  false },
       ['config.dss']            = { bool_1,   true,  false },
       ['config.fill']           = { bool_1,   true,  false },
       ['config.lazy_lock']      = { bool_1,   true,  false },
       ['config.mremap']         = { bool_1,   true,  false },
       ['config.munmap']         = { bool_1,   true,  false },
       ['config.prof']           = { bool_1,   true,  false },
       ['config.prof_libgcc']    = { bool_1,   true,  false },
       ['config.prof_libunwind'] = { bool_1,   true,  false },
       ['config.stats']          = { bool_1,   true,  false },
       ['config.tcache']         = { bool_1,   true,  false },
       ['config.tls']            = { bool_1,   true,  false },
       ['config.utrace']         = { bool_1,   true,  false },
       ['config.valgrind']       = { bool_1,   true,  false },
       ['config.xmalloc']        = { bool_1,   true,  false },
       ['opt.abort']             = { bool_1,   true,  false },
       ['opt.dss']               = { ksz_1,    true,  false },
       ['opt.lg_chunk']          = { size_1,   true,  false },
       ['opt.narenas']           = { size_1,   true,  false },
       ['opt.lg_dirty_mult']     = { ssize_1,  true,  false },
       ['opt.stats_print']       = { bool_1,   true,  false },
       ['opt.junk']              = { bool_1,   true,  false },
       ['opt.quarantine']        = { size_1,   true,  false },
       ['opt.redzone']           = { bool_1,   true,  false },
       ['opt.zero']              = { bool_1,   true,  false },
       ['opt.utrace']            = { bool_1,   true,  false },
       ['opt.valgrind']          = { bool_1,   true,  false },
       ['opt.xmalloc']           = { bool_1,   true,  false },
       ['opt.tcache']            = { bool_1,   true,  false },
       ['opt.lg_1cache_max']     = { size_1,   true,  false },
       ['opt.prof']              = { bool_1,   true,  false },
       ['opt.prof_prefix']       = { ksz_1,    true,  false },
       ['opt.prof_active']       = { bool_1,   true,  true  },
       ['opt.lg_prof_sample']    = { ssize_1,  true,  false },
       ['opt.prof_accum']        = { bool_1,   true,  false },
       ['opt.lg_prof_interval']  = { ssize_1,  true,  false },
       ['opt.prof_gdump']        = { bool_1,   true,  false },
       ['opt.prof_final']        = { bool_1,   true,  false },
       ['opt.prof_leak']         = { bool_1,   true,  false },
       ['thread.arena']          = { uint32_1, true,  true  },
       ['thread.allocated']      = { uint64_1, true,  true  },
       ['thread.deallocated']    = { uint64_1, true,  true  },
       ['thread.tcache.enabled'] = { bool_1,   true,  true  },
       ['thread.tcache.flush']   = { nil,      true,  false },
       ['arenas.narenas']        = { uint32_1, true,  false },
       ['arenas.quantum']        = { size_1,   true,  false },
       ['arenas.page']           = { size_1,   true,  false },
       ['arenas.tcache_max']     = { size_1,   true,  false },
       ['arenas.nbins']          = { uint32_1, true,  false },
       ['arenas.nhbins']         = { uint32_1, true,  false },
       ['arenas.nlruns']         = { size_1,   true,  false },
       ['arenas.purge']          = { uint32_1, false, true  },
       ['arenas.extend']         = { uint32_1, true,  false },
       ['prof.active']           = { bool_1,   true,  true  },
       ['prof.dump']             = { ksz_1,    false, true  },
       ['prof.interval']         = { uint64_1, true,  false },
       ['stats.allocated']       = { size_1,   true,  false },
       ['stats.active']          = { size_1,   true,  false },
       ['stats.mapped']          = { size_1,   true,  false },
       ['stats.chunks.current']  = { size_1,   true,  false },
       ['stats.chunks.total']    = { uint64_1, true,  false },
       ['stats.chunks.high']     = { size_1,   true,  false },
       ['stats.huge.allocated']  = { size_1,   true,  false },
       ['stats.huge.nmalloc']    = { uint64_1, true,  false },
       ['stats.huge.ndalloc']    = { uint64_1, true,  false },
    }

    --[[
       -- TODO: figure this out
       ['thread.allocatedp']     = { (uint64_t *) r- [--enable-stats]
       ['thread.deallocatedp']   = { (uint64_t *) r- [--enable-stats]
       ['arenas.initialized']    = { (bool *) r-
       ['stats.cactive']         = { (size_t *) r- [--enable-stats]
       ['arenas.bin.<i>.size']   = { (size_t) r-
       ['arenas.bin.<i>.nregs']  = { (uint32_t) r-
       ['arenas.bin.<i>.run_size'] = { (size_t) r-
       ['arenas.lrun.<i>.size']    = { (size_t) r-
       ['arena.<i>.purge'] = { (unsigned) --
       ['arena.<i>.dss'] = { (const char *) rw
       ['stats.arenas.<i>.dss'] = { (const char *) r-
       ['stats.arenas.<i>.nthreads'] = { (unsigned) r-
       ['stats.arenas.<i>.pactive'] = { (size_t) r-
       ['stats.arenas.<i>.pdirty'] = { (size_t) r-
       ['stats.arenas.<i>.mapped'] = { (size_t) r- [--enable-stats]
       ['stats.arenas.<i>.npurge'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.nmadvise'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.purged'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.small.allocated'] = { (size_t) r- [--enable-stats]
       ['stats.arenas.<i>.small.nmalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.small.ndalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.small.nrequests'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.large.allocated'] = { (size_t) r- [--enable-stats]
       ['stats.arenas.<i>.large.nmalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.large.ndalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.large.nrequests'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.allocated'] = { (size_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.nmalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.ndalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.nrequests'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.nfills'] = { (uint64_t) r- [--enable-stats
       ['stats.arenas.<i>.bins.<j>.nflushes'] = { (uint64_t) r- [--enable-stats
       ['stats.arenas.<i>.bins.<j>.nruns'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.nreruns'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.bins.<j>.curruns'] = { (size_t) r- [--enable-stats]
       ['stats.arenas.<i>.lruns.<j>.nmalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.lruns.<j>.ndalloc'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.lruns.<j>.nrequests'] = { (uint64_t) r- [--enable-stats]
       ['stats.arenas.<i>.lruns.<j>.curruns'] = { (size_t) r- [--enable-stats]
    --]]

    local mallctl_fname = JEMALLOC_PREFIX..'mallctl'
    local oldlenp = ffi.new('size_t[1]')

    -- TODO: load the MIBs at load-time and use them instead
    function J.mallctl_read( param )
        local entry = mallctl_params[param]
        if not entry then return nil, 'invalid parameter' end
        if not entry[2] then return nil, 'parameter is not readable' end

        local oldp = entry[1]                        -- oldp may be nil for the non-rw entries, 
        oldlenp[0] = oldp and ffi.sizeof(oldp) or 0  -- so set 0 size in that case

        local err = C[mallctl_fname]( param, oldp, oldlenp, nil, 0)
        if err ~= 0 then return nil, err end

        -- convert result to Lua string if needed
        if oldp == ksz_1 then
            return ffi.string(oldp[0])
        else
            return  oldp[0]
        end
    end

    -- TODO: malloctl_write
    function J.mallctl_write( param, value )
        return nil, 'not implemented yet'
    end
end


-- version 3.5 or greater is required
do
    local version_pattern = '^3.5'
    local version_str = J.mallctl_read('version')
    if not string.match(version_str, version_pattern) then
        error('jemalloc version must match "',version_pattern,'", but was "'..version_str..'"')
    end
end


-------------------------------------------------------------------------------
-- bind "non-standard" API

do
    local mallocx_fname = JEMALLOC_PREFIX..'mallocx'
    function J.mallocx( size, flags )
        return C[mallocx_fname]( size, flags or 0 )
    end

    local rallocx_fname = JEMALLOC_PREFIX..'rallocx'
    function J.rallocx( ptr, size, flags)
        return C[rallocx_fname]( ptr, size, flags or 0 )
    end

    local xallocx_fname = JEMALLOC_PREFIX..'xallocx'
    function J.xallocx( ptr, size, extra, flags)
        return C[xallocx_fname]( ptr, size, flags or 0 )
    end

    local sallocx_fname = JEMALLOC_PREFIX..'sallocx'
    function J.sallocx( ptr, flags )
        return C[sallocx_fname]( ptr, flags or 0 )
    end

    local dallocx_fname = JEMALLOC_PREFIX..'dallocx'
    function J.dallocx( ptr, flags)
        return C[dallocx_fname]( ptr, flags or 0 )
    end

    local nallocx_fname = JEMALLOC_PREFIX..'nallocx'
    function J.nallocx( size, flags)
        return C[nallocx_fname]( ptr, flags or 0 )
    end

    local malloc_usable_size_fname = JEMALLOC_PREFIX..'malloc_usable_size'
    function J.malloc_usable_size( ptr )
        return C[malloc_usable_size_fname]( ptr )
    end

    local malloc_stats_print_fname = JEMALLOC_PREFIX..'malloc_stats_print'
    function J.malloc_stats_print()  -- TODO allow user-supplied callback
        C[malloc_stats_print_fname]( nil, nil, nil )
    end

    -- TODO
-- void (*malloc_message)(void *cbopaque, const char *s);
--const char *malloc_conf;
end



-------------------------------------------------------------------------------
-- flag "macros"
--
-- they should be combined with bit.bor
--

-- /* sizeof(void *) == 2^LG_SIZEOF_PTR. */
local LG_SIZEOF_PTR = math.log(ffi.sizeof('void*')) / math.log(2)
local INT_MAX = 2147483647  -- TODO: universally true?

function J.MALLOCX_LG_ALIGN(la)
    return la
end

if LG_SIZEOF_PTR == 2 then
    function J.MALLOCX_ALIGN(a)
        a = a or 0
        return (C.ffs(a)-1)
    end
else
    function J.MALLOCX_ALIGN(a)
        a = a or 0
        return (a < INT_MAX) and (C.ffs(a)-1) or (C.ffs(bit.rshift(a,32))+31)
    end
end

function J.MALLOCX_ZERO()
  return 0x40
end

-- Bias arena index bits so that 0 encodes "MALLOCX_ARENA() unspecified".
function J.MALLOCX_ARNEA(a)
    return bit.lshift((a+1), 8)  -- TODO: limit to 32 bits?
end



-- return public API
return J
