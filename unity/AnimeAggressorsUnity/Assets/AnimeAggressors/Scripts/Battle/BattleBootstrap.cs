using AnimeAggressors.App;
using AnimeAggressors.Data;
using AnimeAggressors.UI;
using UnityEngine;

namespace AnimeAggressors.Battle
{
    /// <summary>
    /// Builds Battle/Training scenes from GameState selections using the
    /// proven CombatProof systems (FighterController, Hitbox/Hurtbox,
    /// HitResolver, ShieldController, GrabController, AuraController).
    /// Versus: battle HUD, pause menu, KO/timer → ResultsScene.
    /// Training: debug HUD, overlays, reset, auto-respawn.
    /// </summary>
    public class BattleBootstrap : MonoBehaviour
    {
        public bool TrainingMode;

        public const float KoDamage = 150f;
        public const float BlastZoneY = -12f;
        public const float MatchLengthSeconds = 99f;

        public FighterController P1 { get; private set; }
        public FighterController P2 { get; private set; }
        public StageDefinition Stage { get; private set; }
        public float TimeRemaining { get; private set; } = MatchLengthSeconds;

        PauseMenuController _pause;
        float _elapsed;
        bool _ended;

        void Start()
        {
            Stage = GameState.SelectedStage;
            BuildStage();
            SpawnFighters();
            BuildUi();
            Debug.Log($"[Battle] {(TrainingMode ? "Training" : "Versus")} on '{Stage.DisplayName}' as {GameState.SelectedCharacter.DisplayName}");
        }

        void BuildStage()
        {
            foreach (var p in Stage.Platforms)
            {
                var cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cube.name = $"Platform ({Stage.DisplayName}) PROXY — NOT FINAL ART";
                cube.transform.position = p.Center;
                cube.transform.localScale = p.Size;
                cube.GetComponent<Renderer>().material.color = p.Color;
            }

            var cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
                cam = camGo.AddComponent<Camera>();
                camGo.AddComponent<AudioListener>();
            }
            cam.transform.position = Stage.CameraPosition;
            cam.transform.rotation = Quaternion.Euler(Stage.CameraEuler);
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Stage.BackgroundColor;

            if (FindFirstObjectByType<Light>() == null)
            {
                var lightGo = new GameObject("Directional Light");
                var light = lightGo.AddComponent<Light>();
                light.type = LightType.Directional;
                lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0);
            }
        }

        void SpawnFighters()
        {
            var def = GameState.SelectedCharacter;
            P1 = SpawnFighter($"P1 ({def.DisplayName})", Stage.SpawnP1, true, def);
            P2 = SpawnFighter("CPU Dummy", Stage.SpawnP2, false, null);
            P2.gameObject.AddComponent<TrainingDummy>();
        }

        static FighterController SpawnFighter(string name, Vector3 pos, bool isPlayer, CharacterDefinition def)
        {
            var go = new GameObject(name);
            go.transform.position = pos;
            var rb = go.AddComponent<Rigidbody>();
            rb.mass = 1f;
            rb.linearDamping = 0.5f;
            var fc = go.AddComponent<FighterController>();
            fc.IsPlayer = isPlayer;

            if (def != null)
                TintFighter(go, def);
            return fc;
        }

        /// <summary>Applies the character's colors to the proxy capsule body.</summary>
        static void TintFighter(GameObject fighter, CharacterDefinition def)
        {
            foreach (var r in fighter.GetComponentsInChildren<Renderer>())
            {
                if (r.gameObject.name.StartsWith("Body"))
                    r.material.color = def.PrimaryColor;
                else if (r.gameObject.name == "FacingIndicator")
                    r.material.color = def.SecondaryColor;
            }
        }

        void BuildUi()
        {
            if (TrainingMode)
            {
                var hudGo = new GameObject("DebugCombatHUD");
                hudGo.AddComponent<DebugCombatHUD>();

                var banner = UiKit.CreateCanvas("TrainingBanner");
                UiKit.Label(banner.transform, $"TRAINING — {Stage.DisplayName}  •  Esc pauses via HUD  •  R reset", 18,
                    new Vector2(380, 425), new Vector2(820, 30), Stage.ThemeColor, TextAnchor.MiddleRight, true);
                UiKit.MenuButton(banner.transform, "EXIT", new Vector2(730, -425), new Vector2(130, 46),
                    () => SceneFlowController.Load(SceneFlowController.MainMenu), new Color(0.55f, 0.60f, 0.75f), 18);
            }
            else
            {
                var hud = new GameObject("BattleHud").AddComponent<BattleHudController>();
                hud.Init(this);
                _pause = new GameObject("PauseMenu").AddComponent<PauseMenuController>();
            }
        }

        void Update()
        {
            if (_ended) return;

            if (TrainingMode)
            {
                // Auto-respawn anyone who falls off the training stage.
                if (P1 != null && P1.transform.position.y < BlastZoneY) P1.ResetFighter(Stage.SpawnP1);
                if (P2 != null && P2.transform.position.y < BlastZoneY) P2.ResetFighter(Stage.SpawnP2);
                return;
            }

            _elapsed += Time.deltaTime;
            TimeRemaining = Mathf.Max(0f, MatchLengthSeconds - _elapsed);

            var p1Name = GameState.SelectedCharacter.DisplayName;

            if (P1.DamagePercent >= KoDamage || P1.transform.position.y < BlastZoneY)
                EndBattle("K.O.!", "CPU Dummy");
            else if (P2.DamagePercent >= KoDamage || P2.transform.position.y < BlastZoneY)
                EndBattle("K.O.!", p1Name);
            else if (TimeRemaining <= 0f)
            {
                if (Mathf.Approximately(P1.DamagePercent, P2.DamagePercent))
                    EndBattle("TIME! DRAW", "");
                else
                    EndBattle("TIME!", P1.DamagePercent < P2.DamagePercent ? p1Name : "CPU Dummy");
            }
        }

        void EndBattle(string headline, string winner)
        {
            _ended = true;
            if (_pause != null) _pause.BlockPause = true;
            GameState.ResultHeadline = headline;
            GameState.WinnerName = winner;
            GameState.P1Damage = P1.DamagePercent;
            GameState.P2Damage = P2.DamagePercent;
            GameState.MatchSeconds = _elapsed;
            Debug.Log($"[Battle] {headline} winner: {(string.IsNullOrEmpty(winner) ? "—" : winner)}");
            Invoke(nameof(GoToResults), 1.2f);
        }

        void GoToResults()
        {
            SceneFlowController.Load(SceneFlowController.Results);
        }
    }
}
