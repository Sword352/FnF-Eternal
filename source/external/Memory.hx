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
     * On Windows, this returns the total amount of memory allocated by the process.
     * On other targets, this returns the amount of memory allocated by the garbage collector.
     */
    #if (cpp && windows)
    @:functionCode('
        PROCESS_MEMORY_COUNTERS_EX pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
            return pmc.WorkingSetSize;
    ')
    #end
    public static function getProcessUsage():Float {
        return openfl.system.System.totalMemoryNumber;
    }
}
