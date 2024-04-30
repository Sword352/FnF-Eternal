package external;

#if (cpp && windows)
@:headerInclude('windows.h')
@:headerInclude('psapi.h')
#end

class Memory {
    #if (cpp && windows)
    @:functionCode('
        PROCESS_MEMORY_COUNTERS pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc)))
            return (int)pmc.WorkingSetSize;
    ')
    #end
    public static function get():Int {
        return 0;
    }
}
