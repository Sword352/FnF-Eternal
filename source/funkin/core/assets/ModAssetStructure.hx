package funkin.core.assets;

#if sys
class ModAssetStructure extends RuntimeAssetStructure {
    public function new(mod:String):Void {
        super(Mods.FOLDER + mod);
    }
}
#end
