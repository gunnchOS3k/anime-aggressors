using AnimeAggressors.App;
using UnityEngine;

namespace AnimeAggressors.UI
{
    public class ResultsScreenController : MonoBehaviour
    {
        void Start()
        {
            var canvas = UiKit.CreateCanvas("ResultsCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);

            var headline = string.IsNullOrEmpty(GameState.ResultHeadline) ? "MATCH OVER" : GameState.ResultHeadline;
            UiKit.Label(canvas.transform, headline, 72, new Vector2(0, 250), new Vector2(1400, 100),
                UiKit.Accent, TextAnchor.MiddleCenter, true);

            if (!string.IsNullOrEmpty(GameState.WinnerName))
                UiKit.Label(canvas.transform, $"{GameState.WinnerName} WINS", 40, new Vector2(0, 165),
                    new Vector2(1200, 60), UiKit.Ink, TextAnchor.MiddleCenter, true);

            var stats = UiKit.PanelBox(canvas.transform, "Stats", new Vector2(0, 30), new Vector2(760, 150), UiKit.Panel);
            UiKit.Label(stats.transform, GameState.SelectedCharacter.DisplayName, 24, new Vector2(-180, 40), new Vector2(360, 36), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(stats.transform, $"took {GameState.P1Damage:F0}% damage", 20, new Vector2(-180, -5), new Vector2(360, 30), UiKit.InkDim);
            UiKit.Label(stats.transform, "CPU Dummy", 24, new Vector2(180, 40), new Vector2(360, 36), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(stats.transform, $"took {GameState.P2Damage:F0}% damage", 20, new Vector2(180, -5), new Vector2(360, 30), UiKit.InkDim);
            UiKit.Label(stats.transform, $"match time {GameState.MatchSeconds:F0}s  •  {GameState.SelectedStage.DisplayName}", 18,
                new Vector2(0, -45), new Vector2(700, 28), new Color(0.5f, 0.55f, 0.68f));

            UiKit.MenuButton(canvas.transform, "REMATCH", new Vector2(0, -140), new Vector2(420, 70),
                SceneFlowController.StartMatch);
            UiKit.MenuButton(canvas.transform, "CHARACTER SELECT", new Vector2(0, -230), new Vector2(420, 70),
                () => SceneFlowController.Load(SceneFlowController.CharacterSelect), new Color(0.35f, 0.85f, 0.95f));
            UiKit.MenuButton(canvas.transform, "MAIN MENU", new Vector2(0, -320), new Vector2(420, 70),
                () => SceneFlowController.Load(SceneFlowController.MainMenu), new Color(0.55f, 0.60f, 0.75f));
        }
    }
}
