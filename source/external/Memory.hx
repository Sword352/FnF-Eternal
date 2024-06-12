package external;

#if (cpp && windows)
@:headerInclude('windows.h')
@:headerInclude('psapi.h')
#end

/**
 * Utility class with the ability to return the program's memory usage.
 */
class Memory {
    /**
     * Returns the amount of memory currently used by the program, in bytes.
     * On Windows, this returns the process memory usage.
     * On any other targets/platforms, this returns the amount of memory the garbage collector is allowed to use.
     */
    #if (cpp && windows)
    @:functionCode('
        PROCESS_MEMORY_COUNTERS pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
            return pmc.WorkingSetSize;
    ')
    #end
    public static function getProcessUsage():Float {
        #if (windows && cpp)
        return 0;
        #elseif hl
        return hl.Gc.stats().currentMemory;
        #else
        return openfl.system.System.totalMemory;
        #end
    }
}
