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
     * On Windows, this returns the process memory usage. Otherwise this returns the amount of memory the garbage collector is allowed to use.
     */
    #if (cpp && windows)
    @:functionCode('
        PROCESS_MEMORY_COUNTERS_EX pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
            return pmc.WorkingSetSize;
    ')
    #end
    public static function getProcessUsage():Float {
        #if hl
        // hashlink specific
        return hl.Gc.stats().currentMemory;
        #else
        // other targets, also serves as a fallback for windows
        return openfl.system.System.totalMemory;
        #end
    }
}
