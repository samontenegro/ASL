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
    settings.Add("TrackLevelProgress", false, "Track Level Progress: display the amount of enemies killed, swag collected and secrets found");

    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // Get loading manager
        var levelLoadingManager = mono["LevelLoadingManager"];
        vars.Helper["IsLoading"] = levelLoadingManager.Make<bool>("Loading");

        // Get level completion totals
        var RunwayManager = mono["RunwayManager"];
        vars.Helper["totalEnemies"] = RunwayManager.Make<int>("Instance", "totalEnemies");
        vars.Helper["totalSecrets"] = RunwayManager.Make<int>("Instance", "totalSecrets");
        vars.Helper["totalSwag"] = RunwayManager.Make<int>("Instance", "totalSwag");

        // Get level completion currents
        vars.Helper["secretsFound"] = RunwayManager.Make<int>("Instance", "secretsFound");
        vars.Helper["swagCollected"] = RunwayManager.Make<int>("Instance", "swagCollected");

        // Enemies are handled differently
        vars.Helper["enemiesList"] = RunwayManager.MakeList<Int32>("Instance", "EnemiesToSpawn");
        return true;
    });

    // set defaults
    current.Scene = "";

    // initialize progress fields
    if (settings["TrackLevelProgress"]) {
        vars.Helper.Texts["Enemies"].Left   = "Enemies";
        vars.Helper.Texts["Swag"].Left      = "Swag";
        vars.Helper.Texts["Secrets"].Left   = "Secrets";
    }
}

update
{
    // update scene data
    current.Scene = vars.Helper.Scenes.Active.Name ?? old.Scene;
    if (old.Scene != current.Scene) vars.Log("Scene updated: " + old.Scene + " -> " + current.Scene);

    // update progress data
    if (settings["TrackLevelProgress"]) {
        vars.Helper.Texts["Enemies"].Right  = current.enemiesList.Count.ToString() + "/" + current.totalEnemies;
        vars.Helper.Texts["Swag"].Right     = current.swagCollected + "/" + current.totalSwag;
        vars.Helper.Texts["Secrets"].Right  = current.secretsFound + "/" + current.totalSecrets;
    }
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
