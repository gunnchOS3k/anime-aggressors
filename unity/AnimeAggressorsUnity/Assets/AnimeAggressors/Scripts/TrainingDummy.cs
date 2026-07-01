using UnityEngine;

namespace AnimeAggressors
{
    public class TrainingDummy : MonoBehaviour
    {
        FighterController _fighter;

        void Awake() => _fighter = GetComponent<FighterController>();

        void Update()
        {
            // Idle dummy — optional shield test with S key on dummy (disabled; P1 tests shield on dummy hits)
        }
    }
}
