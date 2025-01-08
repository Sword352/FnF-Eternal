echo Installing librairies...
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-addons
haxelib git haxeui-core https://github.com/haxeui/haxeui-core
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel
haxelib git yaml https://github.com/Sword352/hx-yaml
haxelib install hxdiscord_rpc
haxelib git hscript-improved https://github.com/Sword352/hscript-improved
haxelib install hxcpp
haxelib install hxcpp-debug-server
echo Setting up Flixel and Lime...
haxelib run lime setup
haxelib run flixel setup
echo Done!