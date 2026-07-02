using AnimeAggressors.App;
using UnityEngine;

namespace AnimeAggressors.UI
{
    public class TitleScreenController : MonoBehaviour
    {
        UnityEngine.UI.Text _prompt;
        float _pulse;

        void Start()
        {
            var canvas = UiKit.CreateCanvas("TitleCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);

            // Title logo (text treatment, PROXY for a real logo).
            UiKit.Label(canvas.transform, "ANIME", 110, new Vector2(0, 150), new Vector2(1400, 130),
                new Color(1f, 0.55f, 0.15f), TextAnchor.MiddleCenter, true);
            UiKit.Label(canvas.transform, "AGGRESSORS", 110, new Vector2(0, 40), new Vector2(1400, 130),
                UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.PanelBox(canvas.transform, "Underline", new Vector2(0, -35), new Vector2(760, 8),
                new Color(1f, 0.45f, 0.15f));
            UiKit.Label(canvas.transform, "an original anime platform fighter", 24, new Vector2(0, -80),
                new Vector2(900, 40), UiKit.InkDim);

            _prompt = UiKit.Label(canvas.transform, "PRESS ANY KEY", 30, new Vector2(0, -220),
                new Vector2(700, 50), UiKit.Ink, TextAnchor.MiddleCenter, true);

            UiKit.Label(canvas.transform, "v0.1 launch-experience  •  PROXY BUILD — NOT FINAL ART", 16,
                new Vector2(0, -410), new Vector2(1000, 30), new Color(0.42f, 0.44f, 0.55f));
        }

        void Update()
        {
            _pulse += Time.deltaTime;
            if (_prompt != null)
            {
                var c = _prompt.color;
                c.a = 0.55f + 0.45f * Mathf.PingPong(_pulse * 1.4f, 1f);
                _prompt.color = c;
            }

            if (Input.anyKeyDown)
                SceneFlowController.Load(SceneFlowController.MainMenu);
        }
    }
}
