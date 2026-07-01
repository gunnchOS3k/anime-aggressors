using UnityEngine;

namespace AnimeAggressors
{
    /// <summary>
    /// Builds CombatProof scene at runtime — open CombatProof.unity and press Play.
    /// </summary>
    public class CombatProofBootstrap : MonoBehaviour
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void AutoLoadIfEmpty()
        {
            if (FindObjectOfType<CombatProofBootstrap>() != null) return;
            if (FindObjectOfType<FighterController>() != null) return;
            var go = new GameObject("CombatProofBootstrap");
            go.AddComponent<CombatProofBootstrap>();
        }

        void Awake()
        {
            if (FindObjectsOfType<FighterController>().Length > 0) return;
            BuildScene();
        }

        void BuildScene()
        {
            // Platform
            var plat = GameObject.CreatePrimitive(PrimitiveType.Cube);
            plat.name = "Platform";
            plat.transform.position = new Vector3(0, -0.5f, 0);
            plat.transform.localScale = new Vector3(20f, 1f, 4f);
            plat.GetComponent<Renderer>().material.color = new Color(0.15f, 0.18f, 0.25f);

            // Camera
            var cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera");
                cam = camGo.AddComponent<Camera>();
                camGo.tag = "MainCamera";
                camGo.AddComponent<AudioListener>();
            }
            cam.transform.position = new Vector3(0, 4f, -12f);
            cam.transform.rotation = Quaternion.Euler(10f, 0, 0);
            cam.backgroundColor = new Color(0.06f, 0.08f, 0.12f);

            // Light
            if (FindObjectOfType<Light>() == null)
            {
                var lightGo = new GameObject("Directional Light");
                var light = lightGo.AddComponent<Light>();
                light.type = LightType.Directional;
                lightGo.transform.rotation = Quaternion.Euler(50f, -30f, 0);
            }

            // P1
            var p1 = CreateFighter("P1", new Vector3(-3f, 1f, 0), true);
            // Dummy
            var dummy = CreateFighter("Dummy", new Vector3(3f, 1f, 0), false);
            dummy.gameObject.AddComponent<TrainingDummy>();

            // HUD
            var hudGo = new GameObject("DebugCombatHUD");
            hudGo.AddComponent<DebugCombatHUD>();

            Debug.Log("[CombatProof] Scene ready — use HUD controls. PROXY visuals, not final art.");
        }

        static FighterController CreateFighter(string name, Vector3 pos, bool isPlayer)
        {
            var go = new GameObject(name);
            go.transform.position = pos;
            var rb = go.AddComponent<Rigidbody>();
            rb.mass = 1f;
            rb.drag = 0.5f;
            var fc = go.AddComponent<FighterController>();
            fc.IsPlayer = isPlayer;
            return fc;
        }
    }
}
