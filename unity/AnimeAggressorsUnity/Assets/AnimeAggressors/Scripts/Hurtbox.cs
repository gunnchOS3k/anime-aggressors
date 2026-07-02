using UnityEngine;

namespace AnimeAggressors
{
    /// <summary>
    /// Damage-receiving trigger volume. The collider stays enabled at all
    /// times; F6 only toggles the blue debug overlay renderer.
    /// </summary>
    [RequireComponent(typeof(BoxCollider))]
    public class Hurtbox : MonoBehaviour
    {
        public FighterController Owner { get; set; }
        public bool DebugVisible { get; private set; } = true;

        MeshRenderer _vis;

        void Awake()
        {
            var col = GetComponent<BoxCollider>();
            col.isTrigger = true;
            _vis = gameObject.AddComponent<MeshRenderer>();
            var filter = gameObject.AddComponent<MeshFilter>();
            filter.sharedMesh = Resources.GetBuiltinResource<Mesh>("Cube.fbx");
            _vis.sharedMaterial = CombatVisuals.Transparent(new Color(0.2f, 0.5f, 1f, 0.25f));
            _vis.enabled = DebugVisible;
        }

        public void Configure(Vector3 size, Vector3 localPos)
        {
            transform.localScale = size;
            transform.localPosition = localPos;
        }

        public void SetDebugVisible(bool on)
        {
            DebugVisible = on;
            if (_vis != null) _vis.enabled = on;
        }
    }
}
