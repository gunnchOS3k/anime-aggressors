using UnityEngine;

namespace AnimeAggressors
{
    [RequireComponent(typeof(BoxCollider))]
    public class Hurtbox : MonoBehaviour
    {
        public FighterController Owner { get; set; }

        void Awake()
        {
            var col = GetComponent<BoxCollider>();
            col.isTrigger = true;
            var vis = gameObject.AddComponent<MeshRenderer>();
            var filter = gameObject.AddComponent<MeshFilter>();
            filter.sharedMesh = Resources.GetBuiltinResource<Mesh>("Cube.fbx");
            vis.sharedMaterial = CombatVisuals.Transparent(new Color(0.2f, 0.5f, 1f, 0.25f));
            gameObject.SetActive(false);
        }

        public void Configure(Vector3 size, Vector3 localPos)
        {
            transform.localScale = size;
            transform.localPosition = localPos;
        }

        public void SetDebugVisible(bool on) => gameObject.SetActive(on);
    }
}
