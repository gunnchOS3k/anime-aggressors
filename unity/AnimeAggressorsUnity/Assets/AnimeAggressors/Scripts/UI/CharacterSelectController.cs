using AnimeAggressors.App;
using AnimeAggressors.Data;
using UnityEngine;
using UnityEngine.UI;

namespace AnimeAggressors.UI
{
    public class CharacterSelectController : MonoBehaviour
    {
        Text _previewName;
        Text _previewMeta;
        Text _previewStyle;
        Text _previewStatus;
        Image _previewSwatch;
        Image _previewAura;

        void Start()
        {
            var canvas = UiKit.CreateCanvas("CharacterSelectCanvas");
            UiKit.Fullscreen(canvas.transform, UiKit.Backdrop);
            UiKit.Header(canvas.transform, "CHARACTER SELECT",
                GameState.Mode == GameMode.Training ? "training — pick your fighter" : "versus — pick your fighter",
                UiKit.Accent);

            // Roster grid: 4 x 2 cards.
            var roster = RosterDatabase.All;
            for (int i = 0; i < roster.Count; i++)
            {
                var col = i % 4;
                var row = i / 4;
                var pos = new Vector2(-540 + col * 360, 165 - row * 190);
                BuildCard(canvas.transform, roster[i], pos);
            }

            // Preview panel.
            var preview = UiKit.PanelBox(canvas.transform, "Preview", new Vector2(0, -255), new Vector2(1160, 170), UiKit.Panel);
            _previewAura = UiKit.PanelBox(preview.transform, "Aura", new Vector2(-495, 0), new Vector2(130, 130), Color.white);
            _previewSwatch = UiKit.PanelBox(_previewAura.transform, "Swatch", Vector2.zero, new Vector2(90, 90), Color.white);
            _previewName = UiKit.Label(preview.transform, "", 34, new Vector2(-90, 45), new Vector2(680, 50), UiKit.Ink, TextAnchor.MiddleLeft, true);
            _previewMeta = UiKit.Label(preview.transform, "", 20, new Vector2(-90, 5), new Vector2(680, 32), UiKit.InkDim, TextAnchor.MiddleLeft);
            _previewStyle = UiKit.Label(preview.transform, "", 19, new Vector2(-90, -38), new Vector2(680, 44), UiKit.Ink, TextAnchor.MiddleLeft);
            _previewStatus = UiKit.Label(preview.transform, "", 18, new Vector2(430, -55), new Vector2(280, 30), UiKit.Accent, TextAnchor.MiddleRight, true);

            UiKit.MenuButton(canvas.transform, "< BACK", new Vector2(-650, -400), new Vector2(220, 58), () =>
            {
                SceneFlowController.Load(GameState.Mode == GameMode.Training
                    ? SceneFlowController.MainMenu
                    : SceneFlowController.ModeSelect);
            }, new Color(0.55f, 0.60f, 0.75f), 20);

            UiKit.MenuButton(canvas.transform, "CONFIRM >", new Vector2(650, -400), new Vector2(220, 58),
                () => SceneFlowController.Load(SceneFlowController.StageSelect), UiKit.Accent, 20);

            RefreshPreview();
        }

        void BuildCard(Transform parent, CharacterDefinition def, Vector2 pos)
        {
            var card = UiKit.PanelBox(parent, $"Card_{def.Id}", pos, new Vector2(330, 165), UiKit.Panel);
            UiKit.PanelBox(card.transform, "Stripe", new Vector2(0, 72), new Vector2(330, 12), def.PrimaryColor);
            UiKit.PanelBox(card.transform, "Portrait", new Vector2(-120, -8), new Vector2(64, 100), def.PrimaryColor);
            UiKit.PanelBox(card.transform, "PortraitAura", new Vector2(-120, -66), new Vector2(64, 12), def.AuraColor);
            UiKit.Label(card.transform, def.DisplayName, 23, new Vector2(35, 30), new Vector2(230, 34), UiKit.Ink, TextAnchor.MiddleLeft, true);
            UiKit.Label(card.transform, def.Element, 16, new Vector2(35, 2), new Vector2(230, 26), UiKit.InkDim, TextAnchor.MiddleLeft);
            UiKit.Label(card.transform, def.Archetype, 16, new Vector2(35, -22), new Vector2(230, 26), UiKit.InkDim, TextAnchor.MiddleLeft);
            UiKit.Label(card.transform, def.Playable ? "PLAYABLE" : "PROXY", 14, new Vector2(35, -52),
                new Vector2(230, 24), def.Playable ? new Color(0.4f, 0.95f, 0.5f) : new Color(0.95f, 0.75f, 0.3f),
                TextAnchor.MiddleLeft, true);

            card.raycastTarget = true;
            var btn = card.gameObject.AddComponent<Button>();
            btn.targetGraphic = card;
            btn.onClick.AddListener(() =>
            {
                GameState.SelectedCharacterId = def.Id;
                RefreshPreview();
            });
        }

        void RefreshPreview()
        {
            var def = GameState.SelectedCharacter;
            _previewName.text = def.DisplayName;
            _previewMeta.text = $"{def.Element}   •   {def.Archetype}";
            _previewStyle.text = def.StyleDescription;
            _previewStatus.text = def.StatusLabel;
            _previewStatus.color = def.Playable ? new Color(0.4f, 0.95f, 0.5f) : new Color(0.95f, 0.75f, 0.3f);
            _previewSwatch.color = def.PrimaryColor;
            _previewAura.color = def.AuraColor;
        }

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                SceneFlowController.Load(GameState.Mode == GameMode.Training
                    ? SceneFlowController.MainMenu
                    : SceneFlowController.ModeSelect);
            if (Input.GetKeyDown(KeyCode.Return))
                SceneFlowController.Load(SceneFlowController.StageSelect);
        }
    }
}
