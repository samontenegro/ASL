state("Fashion Police Squad") {}

startup
{
    // asl-help setup thanks to Ero
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Fashion Police Squad";
    vars.Helper.LoadSceneManager = true;

    vars.UntimedScenes = new List<string> {
        "LoadingScreen",
        "MainMenu"
    };

    // constants
    vars.SPLIT_SCENE        = "Runway";
    vars.START_SCENE        = "001-intro-cinematic";
    vars.WORLD_MAP_SCENE    = "WorldMap";
    vars.LOADING_SCENE      = "LoadingScreen";

    // Optional timing in World
    settings.Add("WorldMapUntimed", false, "Untimed World Map: pause timer while in the World Map");

    vars.Helper.AlertLoadless();
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
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;

    if (old.Scene != current.Scene) vars.Log("Scene updated: " + old.Scene + " -> " + current.Scene);
}

start
{
    if (current.Scene == vars.START_SCENE) return true;
}

split
{
    return current.Scene != old.Scene && current.Scene == vars.SPLIT_SCENE;
}

isLoading
{
    return vars.UntimedScenes.Contains(current.Scene) || (settings["WorldMapUntimed"] && current.Scene == vars.WORLD_MAP_SCENE) || current.IsLoading;
}

exit
{
	timer.IsGameTimePaused = true;
}
