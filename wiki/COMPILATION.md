Before reading this file, keep those in mind:
> - **We only support current versions of libraries, use older versions at your own risk.**
> - **If you still get problems while compiling even after following the steps, consider making an issue in the issues tab.**

There are several instructions in order to compile the installation properly.

1. You must have [Haxe](https://haxe.org/download/) installed. Latest version is recommended, but any versions greater or equal than 4.3.0 should
work fine as well.
2. Download and install [git-scm](https://git-scm.com/downloads).
3. Install the required dependencies, which differs from platform to platform (click on one of the dropdowns below).
<details>
   <summary><h3>Windows</h3></summary>

1. Download and install [Visual Studio Community 2019](https://download.visualstudio.microsoft.com/download/pr/5c9aef4f-a79b-4b72-b379-14273860b285/58398a76f32a0149d38fba79bbf71b6084ccd4200ea665bf2bcd954cdc498c7f/vs_Community.exe) (VSC).
2. Open VSC, and wait for the installer to install any necessary information.
3. Once everything is installed, select the `Individual components` tab, and choose those 2 components:
   * MSVC v142 - VS 2019 C++ x64/x86 build tools
   * Windows SDK (10.0.17763.0)
4. Hit install and wait for the components to install. Once finished, close VSC.
5. Run `setup.bat`, located in the installation's path.
</details>
<details>
   <summary><h3>MacOS</h3></summary>

1. Download and install [Xcode](https://developer.apple.com/xcode/).
2. Run `setup.sh`, located in the installation's path.
</details>
<details>
   <summary><h3>Linux</h3></summary>

1. If it isn't already installed, install g++:
   - For debian based distros: `sudo apt install gcc g++`
   - For arch based distros: `sudo pacman -S gcc g++`
2. Run `setup.sh`, located in the installation's path.
</details>

4. Open a command prompt (CMD), such as Terminal or PowerShell.
5. In your CMD, run `cd <PATH TO THE INSTALLATION>`
6. Run `lime test <platform>` (where `<platform>` should be replaced by the platform you're targetting to, eg. `lime test windows`).
7. Wait for it to compile. If it is the first time compiling the installation, it might take a bit, depending on how powerful your PC is (5 minutes in average).

After following all of the steps properly, the compilation process should be working fine.
<h4>Thank you for installing Eternal Engine, and the team hope you have a great modding journey!</h4>
