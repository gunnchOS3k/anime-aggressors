using UnityEngine;
using UnityEngine.SceneManagement;

namespace AnimeAggressors.App
{
    /// <summary>
    /// Central scene names and transitions:
    /// Boot → Title → MainMenu → ModeSelect → CharacterSelect → StageSelect
    /// → Loading → Battle/Training → Results → (Rematch / CharacterSelect / MainMenu).
    /// </summary>
    public static class SceneFlowController
    {
        public const string Boot = "BootScene";
        public const string Title = "TitleScene";
        public const string MainMenu = "MainMenuScene";
        public const string ModeSelect = "ModeSelectScene";
        public const string CharacterSelect = "CharacterSelectScene";
        public const string StageSelect = "StageSelectScene";
        public const string Loading = "LoadingScene";
        public const string Battle = "BattleScene";
        public const string Training = "TrainingScene";
        public const string Results = "ResultsScene";
        public const string CombatProof = "CombatProof";

        public static void Load(string sceneName)
        {
            Time.timeScale = 1f;
            SceneManager.LoadScene(sceneName);
        }

        public static void LoadViaLoadingScreen(string targetScene)
        {
            GameState.NextSceneAfterLoading = targetScene;
            Load(Loading);
        }

        /// <summary>Loads Battle or Training based on the selected mode.</summary>
        public static void StartMatch()
        {
            LoadViaLoadingScreen(GameState.Mode == GameMode.Training ? Training : Battle);
        }

        public static void QuitGame()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }
    }
}
