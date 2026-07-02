using AnimeAggressors.App;
using UnityEngine;

namespace AnimeAggressors.UI
{
    /// <summary>
    /// Esc toggles a pause overlay during battle. Freezes time while open.
    /// </summary>
    public class PauseMenuController : MonoBehaviour
    {
        public bool BlockPause;

        GameObject _overlay;
        bool _paused;

        void Start()
        {
            var canvas = UiKit.CreateCanvas("PauseCanvas");
            canvas.sortingOrder = 50;

            _overlay = new GameObject("PauseOverlay");
            var rt = _overlay.AddComponent<RectTransform>();
            rt.SetParent(canvas.transform, false);
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;

            UiKit.Fullscreen(_overlay.transform, new Color(0.02f, 0.03f, 0.06f, 0.88f));
            UiKit.Label(_overlay.transform, "PAUSED", 64, new Vector2(0, 210), new Vector2(700, 90), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.PanelBox(_overlay.transform, "Line", new Vector2(0, 160), new Vector2(360, 6), UiKit.Accent);

            UiKit.MenuButton(_overlay.transform, "RESUME", new Vector2(0, 70), new Vector2(420, 70), TogglePause);
            UiKit.MenuButton(_overlay.transform, "CHARACTER SELECT", new Vector2(0, -20), new Vector2(420, 70),
                () => SceneFlowController.Load(SceneFlowController.CharacterSelect), new Color(0.35f, 0.85f, 0.95f));
            UiKit.MenuButton(_overlay.transform, "MAIN MENU", new Vector2(0, -110), new Vector2(420, 70),
                () => SceneFlowController.Load(SceneFlowController.MainMenu), new Color(0.55f, 0.60f, 0.75f));
            UiKit.MenuButton(_overlay.transform, "QUIT GAME", new Vector2(0, -200), new Vector2(420, 70),
                SceneFlowController.QuitGame, new Color(0.85f, 0.30f, 0.30f));

            _overlay.SetActive(false);
        }

        void Update()
        {
            if (BlockPause) return;
            if (Input.GetKeyDown(KeyCode.Escape))
                TogglePause();
        }

        public void TogglePause()
        {
            _paused = !_paused;
            _overlay.SetActive(_paused);
            Time.timeScale = _paused ? 0f : 1f;
        }

        void OnDestroy()
        {
            Time.timeScale = 1f;
        }
    }
}
