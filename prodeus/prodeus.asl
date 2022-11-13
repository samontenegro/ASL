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

    vars.MapSplits = new Dictionary<string, string>() {
        { "intro", "Intro (Tutorial)" },
        { "map_name.map_name_shop", "Shop" },
        { "map_name.map_name_sacrum", "Sacrum" },
        { "map_name.map_name_research", "Research" },
        { "map_name.map_name_fuel", "Fuel" },
        { "map_name.map_name_wretch", "Wretch" },
        { "map_name.map_name_genesis_p1", "Genesis Part 1" },
        { "map_name.map_name_genesis_p2", "Genesis Part 2" },
        { "map_name.map_name_excavation", "Excavation" },
        { "map_name.map_name_memoriam", "Memoriam" },
        { "map_name.map_name_marksman", "Marksman" },
        { "map_name.map_name_descent", "Descent" },
        { "map_name.map_name_hazard", "Hazard" },
        { "map_name.map_name_meltdown", "Meltdown" },
        { "map_name.map_name_forge", "The Forge" },
        { "map_name.map_name_corruption", "Corruption" },
        { "map_name.map_name_atonement", "Atonement" },
        { "map_name.map_name_progenitor", "Progenitor" },
        { "map_name.map_name_hexarchy", "Hexarchy" },
        { "map_name.map_name_trench", "Trench" },
        { "map_name.map_name_spacestation", "Space Station" },
        { "map_name.map_name_aftermath", "Aftermath" },
        { "map_name.map_name_frost", "Frost" },
        { "map_name.map_name_chaos_1", "Gate to Chaos" },
        { "map_name.map_name_chaos_boss_1", "Nexus Distortion" },
        { "map_name.map_name_trial_shotgun", "Trial: Shotgun" },
        { "map_name.map_name_trial_rockets", "Trial: Rockets" },
        { "map_name.map_name_trial_shredders", "Trial: Shredders" },
        { "map_name.map_name_trial_grenade", "Trial: Grenade" },
    };

    vars.DefaultSplits = new List<string>() { "map_name.map_name_chaos_boss_1" };

    settings.Add("map_split", true, "Split on map completion");
    foreach(var split in vars.MapSplits.Keys)
    {
        settings.Add(split, vars.DefaultSplits.Contains(split), vars.MapSplits[split], "map_split");
        settings.SetToolTip(split, "Split on completing the map " + vars.MapSplits[split] + ".");
    }
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
        vars.Helper["loading"] = loadingInfo.Make<bool>("instance", "loading");

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

    // set defaults
    current.Scene = "";
    vars.IsRunStarting = false;
}

update
{
    if (vars.Helper.Scenes.Active.Name != null && vars.Helper.Scenes.Active.Name != "") current.Scene = vars.Helper.Scenes.Active.Name;

    if (old.Scene != current.Scene)
    {
        if (old.Scene == vars.MAIN_MENU_SCENE && current.Scene == vars.MAP_SCENE) vars.IsRunStarting = true;

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
    /* Special case for the intro level */
    if (settings["intro"] && current.mapTitle == vars.FIRST_MISSION_MAP && old.mapTitle == vars.START_MAP)
        return true;
 
    /* Split on map completion */
    return old.Scene != current.Scene && current.Scene == vars.SPLIT_SCENE
        && settings.ContainsKey(current.mapTitle) && settings[current.mapTitle];
}

isLoading
{
    return current.loading;
}

exit
{
    timer.IsGameTimePaused = true;
}