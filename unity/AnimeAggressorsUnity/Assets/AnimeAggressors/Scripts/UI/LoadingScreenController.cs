using System.Collections;
using AnimeAggressors.App;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace AnimeAggressors.UI
{
    public class LoadingScreenController : MonoBehaviour
    {
        Text _dots;
        float _t;

        void Start()
        {
            var stage = GameState.SelectedStage;
            var fighter = GameState.SelectedCharacter;

            var canvas = UiKit.CreateCanvas("LoadingCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);
            UiKit.PanelBox(canvas.transform, "StageTint", new Vector2(0, 0), new Vector2(1700, 260), stage.BackgroundColor);
            UiKit.Label(canvas.transform, stage.DisplayName.ToUpperInvariant(), 54, new Vector2(0, 40),
                new Vector2(1200, 80), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(canvas.transform, $"{fighter.DisplayName}  vs  CPU Dummy", 26, new Vector2(0, -35),
                new Vector2(1000, 44), stage.ThemeColor, TextAnchor.MiddleCenter, true);
            _dots = UiKit.Label(canvas.transform, "LOADING", 24, new Vector2(0, -330), new Vector2(600, 40), UiKit.InkDim);

            UiKit.Label(canvas.transform,
                GameState.Mode == GameMode.Training
                    ? "TIP: F1 HUD  •  F2 hitboxes  •  F6 hurtboxes  •  R reset"
                    : "TIP: hold L to shield — K+L charges your aura, J at full aura bursts",
                18, new Vector2(0, -400), new Vector2(1100, 30), new Color(0.5f, 0.55f, 0.68f));

            StartCoroutine(LoadTarget());
        }

        void Update()
        {
            _t += Time.deltaTime;
            if (_dots != null)
                _dots.text = "LOADING" + new string('.', 1 + (int)(_t * 3f) % 3);
        }

        IEnumerator LoadTarget()
        {
            yield return new WaitForSeconds(0.7f);
            var op = SceneManager.LoadSceneAsync(GameState.NextSceneAfterLoading);
            op.allowSceneActivation = true;
            while (!op.isDone) yield return null;
        }
    }
}
