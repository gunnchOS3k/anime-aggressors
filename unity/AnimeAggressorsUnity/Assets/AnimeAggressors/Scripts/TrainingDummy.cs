using UnityEngine;

namespace AnimeAggressors
{
    /// <summary>
    /// Idle punching-bag behavior for the dummy fighter.
    /// B toggles the dummy's shield so shield block / shield break can be
    /// proven against a real defender.
    /// </summary>
    [RequireComponent(typeof(FighterController))]
    public class TrainingDummy : MonoBehaviour
    {
        public bool ShieldOn { get; private set; }

        FighterController _fighter;

        void Awake() => _fighter = GetComponent<FighterController>();

        void Update()
        {
            if (Input.GetKeyDown(KeyCode.B)) ShieldOn = !ShieldOn;
            if (_fighter.Shield.Broken) ShieldOn = false;
            _fighter.Shield.SetBlocking(ShieldOn);
        }
    }
}
