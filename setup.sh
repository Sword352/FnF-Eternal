echo Installing librairies...
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-addons
haxelib git haxeui-core https://github.com/haxeui/haxeui-core
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel
haxelib install flixel-text-input
haxelib git yaml https://github.com/Sword352/hx-yaml
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc
haxelib install hxvlc
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved
haxelib install hxcpp
haxelib install hxcpp-debug-server
echo Setting up Flixel and Lime...
haxelib run lime setup
haxelib run flixel setup
echo Done!