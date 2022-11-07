state("SIGNALIS") {}

startup
{
    //UnityASL setup thanks to Ero
    vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
    vars.Unity.LoadSceneManager = true;

    // Logging
    vars.outputLineCounter = 0;
    Action<string> DebugOutput = (text) => {
		print(vars.outputLineCounter + " [SIGNALIS ASL] " + text);
        vars.outputLineCounter++;
	};
    vars.DebugOutput = DebugOutput;
    
    // utility
    vars.untimedStates = new int[] {
        4, // gameStates::cutscene
        5, // gameStates::traversing
        9 // gameStates::loading
    };

    // constants
    vars.START_SCENE = "PEN_Wreck";
    vars.LOAD_SCENE = "LoadingScreen";
}

init
{
    vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
    {
        // Get references to classes
        var playerState = helper.GetClass("Assembly-CSharp", "PlayerState");
        vars.Unity.Make<int>(playerState.Static, playerState["gameState"]).Name = "gameState";

        return true;
    });

    vars.GetIsLoading = (Func<bool>)(() => {
        int[] us = vars.untimedStates;
        return Array.Exists(us, e => e == vars.Unity["gameState"].Current);
    });

    vars.Unity.Load(game);

    // set defaults
    current.Scene = "";
    

    // start flags
    vars.isRunStarting = false;
    vars.IsRunStarted = false;
}

update
{
    if (!vars.Unity.Loaded) return false;
	vars.Unity.Update();

    if (vars.Unity.Scenes.Active.Name != "") current.Scene = vars.Unity.Scenes.Active.Name;
    if (current.Scene != old.Scene) vars.DebugOutput("scene: " + old.Scene + " -> " + current.Scene);
}

start
{   
    // start when leaving first loadscreen, right as player gets control
    if (current.Scene == vars.START_SCENE && old.Scene == vars.LOAD_SCENE) {
        vars.isRunStarting = true;
    }

    if (vars.isRunStarting && vars.Unity["gameState"].Current == 0) {
        vars.isRunStarting = false;
        vars.IsRunStarted = true;
        return true;
    }

    return false;
}

onReset
{
    timer.IsGameTimePaused = true;
    vars.IsRunStarted = false;
}

split
{
    // split on scene change, but don't take loadscreens into account
    if (vars.IsRunStarted) {
        if (current.Scene != old.Scene && current.Scene != vars.LOAD_SCENE) return true;
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
	vars.Unity.Reset();
}

shutdown
{
    vars.IsRunStarted = false;
	vars.Unity.Reset();
}