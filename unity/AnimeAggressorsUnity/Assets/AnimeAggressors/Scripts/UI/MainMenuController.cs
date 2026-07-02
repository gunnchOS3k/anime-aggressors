using AnimeAggressors.App;
using UnityEngine;

namespace AnimeAggressors.UI
{
    public class MainMenuController : MonoBehaviour
    {
        void Start()
        {
            var canvas = UiKit.CreateCanvas("MainMenuCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);
            UiKit.Header(canvas.transform, "MAIN MENU", "choose your path", UiKit.Accent);

            var x = 0f;
            UiKit.MenuButton(canvas.transform, "VERSUS", new Vector2(x, 150), new Vector2(460, 78), () =>
            {
                GameState.Mode = GameMode.Versus;
                SceneFlowController.Load(SceneFlowController.ModeSelect);
            });
            UiKit.MenuButton(canvas.transform, "TRAINING", new Vector2(x, 55), new Vector2(460, 78), () =>
            {
                GameState.Mode = GameMode.Training;
                SceneFlowController.Load(SceneFlowController.CharacterSelect);
            }, new Color(0.35f, 0.85f, 0.95f));
            UiKit.MenuButton(canvas.transform, "DEV: COMBAT PROOF", new Vector2(x, -40), new Vector2(460, 78), () =>
            {
                SceneFlowController.Load(SceneFlowController.CombatProof);
            }, new Color(0.55f, 0.60f, 0.75f));
            UiKit.MenuButton(canvas.transform, "QUIT", new Vector2(x, -135), new Vector2(460, 78),
                SceneFlowController.QuitGame, new Color(0.85f, 0.30f, 0.30f));

            UiKit.Label(canvas.transform, "Versus: full menu flow into battle.  Training: pick a fighter and drill on any stage.",
                18, new Vector2(0, -260), new Vector2(1100, 34), UiKit.InkDim);
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                SceneFlowController.Load(SceneFlowController.Title);
        }
    }
}
