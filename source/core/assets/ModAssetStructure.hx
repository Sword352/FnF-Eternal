package core.assets;

#if ENGINE_MODDING
class ModAssetStructure extends RuntimeAssetStructure {
    public function new(mod:String):Void {
        super(Mods.FOLDER + mod);
    }
}
#end
