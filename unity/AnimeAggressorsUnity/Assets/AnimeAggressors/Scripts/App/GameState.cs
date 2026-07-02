using AnimeAggressors.Data;

namespace AnimeAggressors.App
{
    public enum GameMode
    {
        Versus,
        Training,
    }

    /// <summary>
    /// Cross-scene selections and match results. Static on purpose — survives
    /// scene loads without needing a persistent object.
    /// </summary>
    public static class GameState
    {
        public static GameMode Mode = GameMode.Versus;
        public static string SelectedCharacterId = "ember_vale";
        public static string SelectedStageId = "training_grid";
        public static string NextSceneAfterLoading = SceneFlowController.Battle;

        // Last match results (read by ResultsScreenController).
        public static string ResultHeadline = "";
        public static string WinnerName = "";
        public static float P1Damage;
        public static float P2Damage;
        public static float MatchSeconds;

        public static CharacterDefinition SelectedCharacter => RosterDatabase.Get(SelectedCharacterId);
        public static StageDefinition SelectedStage => StageDatabase.Get(SelectedStageId);
    }
}
