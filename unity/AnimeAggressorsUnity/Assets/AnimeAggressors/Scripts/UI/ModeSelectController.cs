using AnimeAggressors.App;
using UnityEngine;

namespace AnimeAggressors.UI
{
    public class ModeSelectController : MonoBehaviour
    {
        void Start()
        {
            var canvas = UiKit.CreateCanvas("ModeSelectCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);
            UiKit.Header(canvas.transform, "MODE SELECT", "how do you want to fight?", UiKit.Accent);

            BuildModeCard(canvas.transform, new Vector2(-330, 40), "VERSUS",
                "Battle a CPU dummy on a chosen stage.\nDamage builds, knockback grows.\nKO at 150% or off the stage.",
                UiKit.Accent, () =>
                {
                    GameState.Mode = GameMode.Versus;
                    SceneFlowController.Load(SceneFlowController.CharacterSelect);
                });

            BuildModeCard(canvas.transform, new Vector2(330, 40), "TRAINING",
                "Free practice with the debug HUD,\nhitbox overlays and instant reset.\nProve your combos here first.",
                new Color(0.35f, 0.85f, 0.95f), () =>
                {
                    GameState.Mode = GameMode.Training;
                    SceneFlowController.Load(SceneFlowController.CharacterSelect);
                });

            UiKit.MenuButton(canvas.transform, "< BACK", new Vector2(-650, -380), new Vector2(220, 60),
                () => SceneFlowController.Load(SceneFlowController.MainMenu), new Color(0.55f, 0.60f, 0.75f), 20);
        }

        static void BuildModeCard(Transform parent, Vector2 pos, string title, string body, Color accent, System.Action onPick)
        {
            var card = UiKit.PanelBox(parent, $"Mode_{title}", pos, new Vector2(560, 420), UiKit.Panel);
            UiKit.PanelBox(card.transform, "Top", new Vector2(0, 190), new Vector2(560, 10), accent);
            UiKit.Label(card.transform, title, 40, new Vector2(0, 120), new Vector2(500, 60), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(card.transform, body, 21, new Vector2(0, -10), new Vector2(480, 180), UiKit.InkDim);
            UiKit.MenuButton(card.transform, $"SELECT {title}", new Vector2(0, -160), new Vector2(340, 64), onPick, accent, 22);
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                SceneFlowController.Load(SceneFlowController.MainMenu);
        }
    }
}
