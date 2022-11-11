state("Prodeus") {}

startup
{
    // asl-help setup thanks to Ero
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;

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
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // Get references to classes
        var loadingInfo = mono["LoadingInfo"];
        var gameInfo = mono["GameInfo"];
        var mapInfo = mono["MapInfo"];

        // Loading data
        vars.Helper["loadingInfoInstance"] = loadingInfo.Make<IntPtr>("instance");

        // Hooks for later, in case the community decides to split or time differently
        vars.Helper["isPaused"] = gameInfo.Make<bool>("isPaused");
        vars.Helper["isCampaignOverworld"] = gameInfo.Make<bool>("isCampaignOverworld");
        vars.Helper["timeStopped"] = gameInfo.Make<bool>("timeStopped");

        // game data
        vars.Helper["mapTitle"] = gameInfo.MakeString("mapTitle");

        // map info
        vars.Helper["timeStart"] = mapInfo.Make<float>("timeStart");

        return true;
    });

    vars.GetIsLoading = (Func<IntPtr, bool>)((instanceAddr) => {
        return memory.ReadValue<bool>(instanceAddr + 0x98); // offset into static class field is 0x98 (hex) --> 144 (dec)
    });

    // set defaults
    current.Scene = "";
    vars.IsRunStarting = false;
}

update
{
    if (vars.Helper.Scenes.Active.Name != null && vars.Helper.Scenes.Active.Name != "") 
    {
        current.Scene = vars.Helper.Scenes.Active.Name;
    }

    if (old.Scene != current.Scene)
    {
        if (old.Scene == vars.MAIN_MENU_SCENE && current.Scene == vars.MAP_SCENE)
        {
            vars.IsRunStarting = true;
            vars.DebugOutput("vars.IsRunStarting = true");
        }

        vars.DebugOutput("OLD SCENE -> " + old.Scene);
        vars.DebugOutput("NEW SCENE -> " + current.Scene);
        vars.DebugOutput("MAP TITLE -> " + current.mapTitle);
    }
}

start
{   
    if (vars.IsRunStarting) {

        // wait for timer to start on first level
        if (old.timeStart != current.timeStart && current.mapTitle == vars.START_MAP) {

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
    return vars.GetIsLoading(current.loadingInfoInstance);
}

exit
{
    timer.IsGameTimePaused = true;
}