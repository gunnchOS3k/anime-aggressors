using AnimeAggressors.App;
using AnimeAggressors.Data;
using UnityEngine;
using UnityEngine.UI;

namespace AnimeAggressors.UI
{
    public class StageSelectController : MonoBehaviour
    {
        Text _previewLabel;

        void Start()
        {
            var canvas = UiKit.CreateCanvas("StageSelectCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);
            UiKit.Header(canvas.transform, "STAGE SELECT",
                $"fighter: {GameState.SelectedCharacter.DisplayName}", UiKit.Accent);

            var stages = StageDatabase.All;
            for (int i = 0; i < stages.Count; i++)
            {
                var pos = new Vector2(-460 + i * 460, 60);
                BuildStageCard(canvas.transform, stages[i], pos);
            }

            _previewLabel = UiKit.Label(canvas.transform, "", 24, new Vector2(0, -260), new Vector2(1100, 40),
                UiKit.Ink, TextAnchor.MiddleCenter, true);

            UiKit.MenuButton(canvas.transform, "< BACK", new Vector2(-650, -400), new Vector2(220, 58),
                () => SceneFlowController.Load(SceneFlowController.CharacterSelect), new Color(0.55f, 0.60f, 0.75f), 20);
            UiKit.MenuButton(canvas.transform, GameState.Mode == GameMode.Training ? "START TRAINING >" : "START BATTLE >",
                new Vector2(620, -400), new Vector2(290, 58), SceneFlowController.StartMatch, UiKit.Accent, 20);

            RefreshPreview();
        }

        void BuildStageCard(Transform parent, StageDefinition stage, Vector2 pos)
        {
            var card = UiKit.PanelBox(parent, $"Stage_{stage.Id}", pos, new Vector2(420, 330), UiKit.Panel);

            // Mini stage preview: background + platform silhouettes.
            var view = UiKit.PanelBox(card.transform, "View", new Vector2(0, 70), new Vector2(380, 160), stage.BackgroundColor);
            foreach (var p in stage.Platforms)
            {
                var c = new Vector2(p.Center.x * 12f, p.Center.y * 12f + 20f);
                var s = new Vector2(Mathf.Min(p.Size.x * 12f, 360f), Mathf.Max(p.Size.y * 10f, 6f));
                UiKit.PanelBox(view.transform, "Plat", c, s, p.Color * 1.6f);
            }

            UiKit.Label(card.transform, stage.DisplayName, 26, new Vector2(0, -40), new Vector2(380, 36), UiKit.Ink, TextAnchor.MiddleCenter, true);
            UiKit.Label(card.transform, stage.Description, 17, new Vector2(0, -85), new Vector2(370, 60), UiKit.InkDim);
            UiKit.Label(card.transform, stage.StatusLabel, 15, new Vector2(0, -135), new Vector2(370, 24),
                stage.Playable ? new Color(0.4f, 0.95f, 0.5f) : new Color(0.95f, 0.75f, 0.3f), TextAnchor.MiddleCenter, true);
            UiKit.PanelBox(card.transform, "Bottom", new Vector2(0, -160), new Vector2(420, 8), stage.ThemeColor);

            card.raycastTarget = true;
            var btn = card.gameObject.AddComponent<Button>();
            btn.targetGraphic = card;
            btn.onClick.AddListener(() =>
            {
                GameState.SelectedStageId = stage.Id;
                RefreshPreview();
            });
        }

        void RefreshPreview()
        {
            var s = GameState.SelectedStage;
            _previewLabel.text = $"selected stage:  {s.DisplayName}";
            _previewLabel.color = s.ThemeColor;
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                SceneFlowController.Load(SceneFlowController.CharacterSelect);
            if (Input.GetKeyDown(KeyCode.Return))
                SceneFlowController.StartMatch();
        }
    }
}
