# Promod - The competetive BF3 experience

This mod is heavily based on the Call of Duty 4 Promod, and kinda works like CS:GO's defusal gametype. Attackers need to kill all enemies or plant the bomb before the timer runs out. Defenders need to defend both bombsites or wait for the timer to run down.

## Screenshots
![Teams](https://github.com/kaloczikvn/kPM/blob/master/assets/teams.jpg?raw=true "Teams")
![Loadouts](https://github.com/kaloczikvn/kPM/blob/master/assets/loadouts.jpg?raw=true "Loadouts")
![Warmup](https://github.com/kaloczikvn/kPM/blob/master/assets/warmup.jpg?raw=true "Warmup")
![Win](https://github.com/kaloczikvn/kPM/blob/master/assets/win.jpg?raw=true "Win")

## Config
You can find and modify the config file here: ext\Shared\kPMConfig.lua

## Maplist.txt
**Warning: You might experience crashes when loading the next map, the code is optimized for single map use only!**

    XP2_Skybar TeamDeathMatchC0 2
    MP_017 TeamDeathMatch0 2
    MP_011 TeamDeathMatch0 2
    MP_001 TeamDeathMatch0 2
You can create your maps too! Modify the *MapsConfig.lua* to create your own map.

## Issues
If you encounter any issues while playing Promod, please let me know by adding a ticket on the GitHub repo's issue page: https://github.com/kaloczikvn/kPM/issues

## Developers
##### Setup
- Install [nodejs](https://nodejs.org/en/).
- Download Promod files and place them in ```.../Server/Admin/Mods```. Path should look like ```.../Server/Admin/Mods/kPM```.
- Add `kPM` to your modlist.txt file.
- Open cmd, cd to ```.../Server/Admin/Mods/kPM/ui``` and run ```npm install```.
- After all the dependencies are installed run ```npm run build``` or if you want to test in the browser run ```npm run start```.

##### Translations
You can create your own translations! The translation strings is located in: ```kPM/ui/srs/translations.ts```. Please create a pull request if you want your translation to be included in the official version.

Language can be set by the admin in the ```ext/Shared/kPMConfig.lua``` file using the `ServerLanguage` variable.

**Warning:** In the string `'Round {round}': 'Round {round}'`, `{round}` should remain the same for every language. It is replaced programmatically.

## Config
The Promod config can be found here: ```ext/Shared/kPMConfig.lua```.
Please set the `AdminName` to your name!

## Download
Promod is a work in progress mod so keep in mind that.
[Release version](https://community.veniceunleashed.net/uploads/short-url/7hqryTpYuHlROTpVY5o8rU4LLKi.zip)
