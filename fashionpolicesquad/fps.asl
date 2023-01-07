state("Fashion Police Squad") {}

startup
{
    // asl-help setup thanks to Ero
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;

    // logger
    vars.outputLineCounter = 0;
    Action<string> DebugOutput = (text) => {
		print(vars.outputLineCounter + " [Fashion Police Squad ASL] " + text);
        vars.outputLineCounter++;
	};
    vars.DebugOutput = DebugOutput;

    vars.UntimedScenes = new List<String>() {
        "LoadingScreen",
        "MainMenu"
    };

    // constants
    vars.SPLIT_SCENE        = "Runway";
    vars.START_SCENE        = "001-intro-cinematic";
    vars.WORLD_MAP_SCENE    = "WorldMap";
    vars.LOADING_SCENE      = "LoadingScreen";

    // Setting setup by Meta
    // Asks user to change to game time if LiveSplit is currently set to Real Time.
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Fashion Police Squad",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );
        
        if (timingMessage == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
    }

    // Optional timing in World
    settings.Add("WorldMapUntimed", false, "Untimed World Map: pause timer while in the World Map");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // Get references to classes
        var levelLoadingManger = mono["LevelLoadingManager"];
        vars.Helper["IsLoading"] = levelLoadingManger.Make<bool>("Loading");
        return true;
    });

    // set defaults
    current.Scene = "";
}

update
{
    try { if (vars.Helper.Scenes.Active.Name != "") current.Scene = vars.Helper.Scenes.Active.Name; }
    catch (System.ComponentModel.Win32Exception) { /* Ignore handle exceptions */ }

    if (old.Scene != current.Scene) vars.DebugOutput("Scene updated: " + old.Scene + " -> " + current.Scene);
}

start
{
    timer.IsGameTimePaused = false;
    if (current.Scene == vars.START_SCENE) return true;
}

onReset
{
    timer.IsGameTimePaused = true;
}

split
{
    return current.Scene != old.Scene && current.Scene == vars.SPLIT_SCENE;
}

isLoading
{
    return vars.UntimedScenes.Contains(current.Scene) || (settings["WorldMapUntimed"] && current.Scene == vars.WORLD_MAP_SCENE) ||vars.Helper["IsLoading"].Current;
}

exit
{
	timer.IsGameTimePaused = true;
}