using AnimeAggressors.Battle;
using AnimeAggressors.UI;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace AnimeAggressors.App
{
    /// <summary>
    /// Persistent app bootstrapper. Scenes in this project are authored as
    /// minimal files; GameBootstrap builds the correct controller for
    /// whichever scene is active, so any scene can be opened directly in the
    /// editor and still work. CombatProof keeps its own dev bootstrap.
    /// </summary>
    public class GameBootstrap : MonoBehaviour
    {
        static GameBootstrap _instance;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void AutoCreate()
        {
            if (_instance != null) return;
            var go = new GameObject("GameBootstrap");
            DontDestroyOnLoad(go);
            _instance = go.AddComponent<GameBootstrap>();
        }

        void Awake()
        {
            SceneManager.sceneLoaded += OnSceneLoaded;
            BuildForScene(SceneManager.GetActiveScene());
        }

        void OnDestroy()
        {
            SceneManager.sceneLoaded -= OnSceneLoaded;
        }

        void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            if (mode != LoadSceneMode.Single) return;
            BuildForScene(scene);
        }

        static void BuildForScene(Scene scene)
        {
            switch (scene.name)
            {
                case SceneFlowController.Boot:
                    Create<BootScreenController>("BootScreen");
                    break;
                case SceneFlowController.Title:
                    Create<TitleScreenController>("TitleScreen");
                    break;
                case SceneFlowController.MainMenu:
                    Create<MainMenuController>("MainMenu");
                    break;
                case SceneFlowController.ModeSelect:
                    Create<ModeSelectController>("ModeSelect");
                    break;
                case SceneFlowController.CharacterSelect:
                    Create<CharacterSelectController>("CharacterSelect");
                    break;
                case SceneFlowController.StageSelect:
                    Create<StageSelectController>("StageSelect");
                    break;
                case SceneFlowController.Loading:
                    Create<LoadingScreenController>("LoadingScreen");
                    break;
                case SceneFlowController.Battle:
                    Create<BattleBootstrap>("BattleBootstrap").TrainingMode = false;
                    break;
                case SceneFlowController.Training:
                    Create<BattleBootstrap>("BattleBootstrap").TrainingMode = true;
                    break;
                case SceneFlowController.Results:
                    Create<ResultsScreenController>("ResultsScreen");
                    break;
                // CombatProof: handled by CombatProofBootstrap (dev scene).
            }
        }

        static T Create<T>(string name) where T : Component
        {
            var existing = Object.FindFirstObjectByType<T>();
            if (existing != null) return existing;
            return new GameObject(name).AddComponent<T>();
        }
    }

    /// <summary>Boot splash: brief studio/engine line, then the title screen.</summary>
    public class BootScreenController : MonoBehaviour
    {
        float _t;

        void Start()
        {
            var canvas = UiKit.CreateCanvas("BootCanvas");
            UiKit.Fullscreen(canvas.transform, new Color(0.02f, 0.02f, 0.05f));
            UiKit.Label(canvas.transform, "ANIME AGGRESSORS", 54, new Vector2(0, 30), new Vector2(1200, 90), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(canvas.transform, "booting combat systems…", 22, new Vector2(0, -40), new Vector2(800, 40), new Color(0.55f, 0.60f, 0.75f));
            UiKit.Label(canvas.transform, "PROXY BUILD — NOT FINAL ART", 16, new Vector2(0, -400), new Vector2(800, 30), new Color(0.45f, 0.45f, 0.55f));
        }

        void Update()
        {
            _t += Time.deltaTime;
            if (_t > 1.4f || Input.anyKeyDown)
                SceneFlowController.Load(SceneFlowController.Title);
        }
    }
}
