using System.Collections;
using UnityEngine;

namespace AnimeAggressors
{
    /// <summary>
    /// Proxy feedback visuals (PROXY — NOT FINAL ART): transparent materials,
    /// shield/aura spheres, and expanding hit sparks.
    /// </summary>
    public static class CombatVisuals
    {
        public static Material Transparent(Color c)
        {
            var shader = Shader.Find("Standard");
            if (shader == null) shader = Shader.Find("Universal Render Pipeline/Lit");
            var m = new Material(shader);
            m.color = c;
            m.SetFloat("_Mode", 3);
            m.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            m.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            m.SetInt("_ZWrite", 0);
            m.DisableKeyword("_ALPHATEST_ON");
            m.EnableKeyword("_ALPHABLEND_ON");
            m.renderQueue = 3000;
            return m;
        }

        public static GameObject MakeSphere(Transform parent, string name, Color color, float scale, Vector3 localPos)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name = name;
            Object.Destroy(go.GetComponent<Collider>());
            go.transform.SetParent(parent, false);
            go.transform.localPosition = localPos;
            go.transform.localScale = Vector3.one * scale;
            go.GetComponent<Renderer>().sharedMaterial = Transparent(color);
            return go;
        }

        public static void SpawnHitSpark(Vector3 pos, Color color, float maxScale = 1.5f, float life = 0.18f)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name = "HitSpark";
            Object.Destroy(go.GetComponent<Collider>());
            go.transform.position = pos;
            go.transform.localScale = Vector3.one * 0.3f;
            go.GetComponent<Renderer>().sharedMaterial = Transparent(color);
            var runner = go.AddComponent<EffectRunner>();
            runner.Run(ExpandAndDie(go, maxScale, life));
        }

        static IEnumerator ExpandAndDie(GameObject go, float maxScale, float life)
        {
            float t = 0f;
            while (t < life)
            {
                t += Time.deltaTime;
                go.transform.localScale = Vector3.one * Mathf.Lerp(0.3f, maxScale, t / life);
                yield return null;
            }
            Object.Destroy(go);
        }

        class EffectRunner : MonoBehaviour
        {
            public void Run(IEnumerator routine) => StartCoroutine(routine);
        }
    }
}
