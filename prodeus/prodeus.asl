state("Prodeus") {}

startup
{
    //UnityASL setup thanks to Ero
    vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
    vars.Unity.LoadSceneManager = true;

    // Logging
    vars.outputLineCounter = 0;
    Action<string> DebugOutput = (text) => {
		print(vars.outputLineCounter + " [Prodeus ASL] " + text);
        vars.outputLineCounter++;
	};

    vars.DebugOutput = DebugOutput;

    // constants
    vars.START_MAP = "map_name.map_name_intro";
    vars.FIRST_MISSION_MAP = "map_name.map_name_sacrum";
    vars.SHOP_MAP = "map_name.map_name_shop";
    vars.SPLIT_SCENE = "LevelComplete";
    vars.MAIN_MENU_SCENE = "MainMenu";
    vars.MAP_SCENE = "MapLoader";

    // settings
    settings.Add("introSplit", false, "Split After Intro Level");
    settings.Add("shopSplit", false, "Split when leaving shop");
}

init
{
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
    {
        // Get references to classes
        var loadingInfo = helper.GetClass("Assembly-CSharp", "LoadingInfo");
        var gameInfo = helper.GetClass("Assembly-CSharp", "GameInfo");
        var mapInfo = helper.GetClass("Assembly-CSharp", "MapInfo");

        // Loading data
        vars.Unity.Make<IntPtr>(loadingInfo.Static, loadingInfo["instance"]).Name = "loadingInfoInstance";

        // Hooks for later, in case the community decides to split or time differently
        vars.Unity.Make<bool>(gameInfo.Static, gameInfo["isPaused"]).Name = "isPaused";
        vars.Unity.Make<bool>(gameInfo.Static, gameInfo["isCampaignOverworld"]).Name = "isCampaignOverworld";
        vars.Unity.Make<bool>(gameInfo.Static, gameInfo["timeStopped"]).Name = "isTimeStopped";

        // game data
        vars.Unity.MakeString(gameInfo.Static, gameInfo["mapTitle"]).Name = "mapTitle";

        // map info
        vars.Unity.Make<float>(mapInfo.Static, mapInfo["timeStart"]).Name = "timeStart";

        return true;
    });

    vars.GetIsLoading = (Func<bool>)(() => {
        bool isLoading = false;
        IntPtr instanceAddr = vars.Unity["loadingInfoInstance"].Current;
        isLoading = memory.ReadValue<bool>(instanceAddr + 152); // offset into static class field is 0x98 (hex) --> 144 (dec)

        return isLoading;
    });

    vars.Unity.Load(game);

    // set defaults
    current.Scene = "";
    vars.IsRunStarting = false;
}

update
{
    if (!vars.Unity.Loaded) return false;
	vars.Unity.Update();

    if (vars.Unity.Scenes.Active.Name != "") current.Scene = vars.Unity.Scenes.Active.Name;
    current.TimeStart = vars.Unity["timeStart"].Current;
    current.mapTitle = vars.Unity["mapTitle"].Current;

    if (old.Scene != current.Scene)
    {
        if (old.Scene == vars.MAIN_MENU_SCENE && current.Scene == vars.MAP_SCENE) vars.IsRunStarting = true;

        vars.DebugOutput("OLD SCENE -> " + old.Scene);
        vars.DebugOutput("NEW SCENE -> " + current.Scene);
        vars.DebugOutput("MAP TITLE -> " + vars.Unity["mapTitle"].Current);
    }
}

start
{   
    if (vars.IsRunStarting) {

        // wait for timer to start on first level
        if (old.TimeStart != current.TimeStart && vars.Unity["mapTitle"].Current == vars.START_MAP) {

            // new initial time was set, which means a level started
            vars.IsRunStarting = false;
            return true;
        }
    }
    return false;
}

onReset
{
    timer.IsGameTimePaused = true;
}

split
{
    if (current.Scene != old.Scene && current.Scene == vars.SPLIT_SCENE) {
        if (!settings["shopSplit"] && current.mapTitle == vars.SHOP_MAP) return false;
        else return true;
    }

    if (settings["introSplit"] && current.mapTitle == vars.FIRST_MISSION_MAP && old.mapTitle == vars.START_MAP) return true;
}

isLoading
{
    return vars.GetIsLoading();
}

exit
{
	timer.IsGameTimePaused = true;
	vars.Unity.Reset();
}

shutdown
{
	vars.Unity.Reset();
}