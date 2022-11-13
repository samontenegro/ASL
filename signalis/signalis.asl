state("SIGNALIS") {}

startup
{
    //asl-help setup thanks to Ero
    Assembly.Load(File.ReadAllBytes(@"Components\asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Signalis";
    vars.Helper.LoadSceneManager = true;

    // Logging
    vars.outputLineCounter = 0;
    Action<string> DebugOutput = (text) => {
		print(vars.outputLineCounter + " [SIGNALIS ASL] " + text);
        vars.outputLineCounter++;
	};
    vars.DebugOutput = DebugOutput;
    
    // utility
    vars.untimedStates = new Dictionary<string, int>() {
        {"Cutscene", 4},    // gameStates::cutscene
        {"Traversal", 5},   // gameStates::traversing
        {"Loading", 9}      // gameStates::loading
    };

    // constants
    vars.START_SCENE = "PEN_Wreck";
    vars.END_SCENE = "EndCredits";
    vars.LOAD_SCENE = "LoadingScreen";

    // Dynamic splits and settings
    dynamic[,] settingsArray =
    {
        { "Settings", true, "Settings", null},
            { "removeCutscenes",    true, "Remove Cutscenes: do not time while cutscenes are running", "Settings"},
            { "removeTraversal",    true, "Remove Transitions: do not time while entering / exiting rooms", "Settings"},
        { "Splits", true, "Splits", null},
            // Mandatory { "PEN_Wreck", true, "Initial level", "Splits"},
            { "PEN_Hole",           true, "Penrose Hole Desc",      "Splits"},
            { "LOV_Reeducation",    true, "Reeducation (LOV) Desc", "Splits"},
            { "DET_Detention",      true, "Detention Desc",         "Splits"},
            { "MED_Medical",        true, "Medical Desc",           "Splits"},
            { "RES_School",         true, "School Desc",            "Splits"},
            { "RES_Residential",    true, "Residential Desc",       "Splits"},
            { "EXC_Mines",          true, "Mines Desc",             "Splits"},
            { "EXC_Gestade",        true, "Gestade (EXC) Desc",     "Splits"},
            { "LAB_Labyrinth",      true, "Labyrinth Desc",         "Splits"},
            { "LAB_Emptiness",      true, "Emptiness Desc",         "Splits"},
            { "MEM_Memory",         true, "Memory Desc",            "Splits"},
            { "MEM_Gestade",        true, "Gestade (MEM) Desc",     "Splits"},
            { "BIO_Reeducation",    true, "Reeducation (BIO) Desc", "Splits"},
            { "ROT_Rotfront",       true, "Rotfront Desc",          "Splits"},
            { "BOS_Adler",          true, "Adler Desc",             "Splits"}
            // Mandatory { "EndCredits", true, "Credits", "Splits"},
    };

    vars.settingsArray = settingsArray;
    vars.splitLocations = new List<string>();

    // build split locations and script settings
    for (int i = 0; i < vars.settingsArray.GetLength(0); i++)
    {
        string sceneName = vars.settingsArray[i, 0];
        bool defaultSetting = vars.settingsArray[i, 1];
        string description = vars.settingsArray[i, 2];
        string parent = vars.settingsArray[i, 3];

        settings.Add(sceneName, defaultSetting, description, parent);
        if (parent == "Splits") vars.splitLocations.Add(sceneName);
    }
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(helper =>
    {
        // Get references to classes
        var playerState = helper.GetClass("Assembly-CSharp", "PlayerState");
        vars.Helper["gameState"] = playerState.Make<int>("gameState");
        return true;
    });

    vars.GetIsLoading = (Func<bool>)(() => {
        bool isLoading = false;
        int gameState = vars.Helper["gameState"].Current;

        // return immediately if its not an untimed state
        if (!vars.untimedStates.ContainsValue(gameState)) return false;
        if (settings["removeCutscenes"] && vars.untimedStates["Cutscene"] == gameState) isLoading = true;
        if (settings["removeTraversal"] && vars.untimedStates["Traversal"] == gameState) isLoading = true;
        return isLoading;
    });

    // set defaults
    current.Scene = "";
    
    // start flags
    vars.isRunStarting = false;
    vars.IsRunStarted = false;
}

update
{
    if (vars.Helper.Scenes.Active.Name != "" && vars.Helper.Scenes.Active.Name != null) current.Scene = vars.Helper.Scenes.Active.Name;
    if (current.Scene != old.Scene) vars.DebugOutput("scene: " + old.Scene + " -> " + current.Scene);
}

start
{   
    // start when leaving first loadscreen, right as player gets control
    if (current.Scene == vars.START_SCENE) {
        vars.isRunStarting = true;
    }

    if (vars.isRunStarting && vars.Helper["gameState"].Current == 0) {
        vars.isRunStarting = false;
        vars.IsRunStarted = true;
        return true;
    }

    return false;
}

onStart
{
    vars.IsRunStarted = true;
}

onReset
{
    timer.IsGameTimePaused = true;
    vars.IsRunStarted = false;
}

split
{
    // split on scene change, but only if a run is ongoing
    if (vars.IsRunStarted && current.Scene != old.Scene) {
        
        // check if scene changed and if it belongs in the valid split locations based on Scene names
        if (vars.splitLocations.Contains(current.Scene)) return settings[current.Scene];

        // Check if scene is the end credits
        if (current.Scene == vars.END_SCENE) return true;
    }

    return false;
}

isLoading
{
    return vars.GetIsLoading();
}

exit
{
	timer.IsGameTimePaused = true;
    vars.IsRunStarted = false;
}

shutdown
{
    vars.IsRunStarted = false;
}