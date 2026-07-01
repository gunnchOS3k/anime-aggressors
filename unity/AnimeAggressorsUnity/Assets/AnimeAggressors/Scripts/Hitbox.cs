using System;
using UnityEngine;

namespace AnimeAggressors
{
    [RequireComponent(typeof(BoxCollider))]
    public class Hitbox : MonoBehaviour
    {
        public FighterController Owner { get; set; }
        public bool Active { get; private set; }

        BoxCollider _col;
        MeshRenderer _vis;

        void Awake()
        {
            _col = GetComponent<BoxCollider>();
            _col.isTrigger = true;
            _col.enabled = false;
            _vis = gameObject.AddComponent<MeshRenderer>();
            var filter = gameObject.AddComponent<MeshFilter>();
            filter.sharedMesh = Resources.GetBuiltinResource<Mesh>("Cube.fbx");
            _vis.sharedMaterial = CombatVisuals.Transparent(new Color(1f, 0.2f, 0.2f, 0.45f));
            gameObject.SetActive(false);
        }

        public void Configure(Vector3 size, Vector3 localPos)
        {
            transform.localScale = size;
            transform.localPosition = localPos;
        }

        public void SetActiveHitbox(bool on)
        {
            Active = on;
            _col.enabled = on;
            gameObject.SetActive(on);
        }

        void OnTriggerEnter(Collider other)
        {
            if (!Active || Owner == null) return;
            var hurt = other.GetComponent<Hurtbox>();
            if (hurt == null || hurt.Owner == null || hurt.Owner == Owner) return;
            Owner.TryHit(hurt.Owner);
        }
    }
}
