using System.Collections.Generic;
using UnityEngine;

namespace AnimeAggressors
{
    [RequireComponent(typeof(Rigidbody))]
    public class FighterController : MonoBehaviour
    {
        public bool IsPlayer;
        public float Weight = 100f;
        public int Facing = 1;

        public float DamagePercent { get; private set; }
        public int ComboCount { get; private set; }
        public string LastHitResult { get; private set; } = "—";
        public bool IsGrounded { get; private set; }
        public Vector3 Velocity => _rb.velocity;

        public FighterStateMachine StateMachine { get; private set; }
        public MoveRunner MoveRunner { get; private set; }
        public ShieldController Shield { get; private set; }
        public GrabController Grab { get; private set; }
        public AuraController Aura { get; private set; }

        Rigidbody _rb;
        Hitbox _hitbox;
        Hurtbox _hurtbox;
        Transform _body;
        Dictionary<string, MoveDefinition> _moves = new Dictionary<string, MoveDefinition>();
        float _hitstunTimer;
        float _hitstopTimer;
        float _simAccum;
        bool _grabbed;
        FighterController _grabbedBy;
        HashSet<FighterController> _hitThisMove = new HashSet<FighterController>();

        public static FighterController Player;
        public static FighterController Dummy;

        void Awake()
        {
            _rb = GetComponent<Rigidbody>();
            _rb.constraints = RigidbodyConstraints.FreezePositionZ | RigidbodyConstraints.FreezeRotation;
            _rb.interpolation = RigidbodyInterpolation.Interpolate;
            StateMachine = new FighterStateMachine();
            MoveRunner = new MoveRunner();
            Shield = new ShieldController(this);
            Grab = new GrabController(this);
            Aura = new AuraController(this);
            MoveRunner.PhaseChanged += OnPhaseChanged;
            MoveRunner.MoveEnded += OnMoveEnded;
            BuildVisuals();
            BuildHitboxes();
            LoadMoves();
            if (IsPlayer) Player = this;
            else Dummy = this;
        }

        void BuildVisuals()
        {
            _body = GameObject.CreatePrimitive(PrimitiveType.Capsule).transform;
            _body.SetParent(transform, false);
            _body.localPosition = new Vector3(0, 1f, 0);
            Destroy(_body.GetComponent<Collider>());
            _body.GetComponent<Renderer>().material.color = IsPlayer ? new Color(0.9f, 0.35f, 0.2f) : new Color(0.3f, 0.5f, 0.9f);
        }

        void BuildHitboxes()
        {
            var hbGo = new GameObject("Hitbox");
            hbGo.transform.SetParent(transform, false);
            _hitbox = hbGo.AddComponent<Hitbox>();
            _hitbox.Owner = this;

            var huGo = new GameObject("Hurtbox");
            huGo.transform.SetParent(transform, false);
            _hurtbox = huGo.AddComponent<Hurtbox>();
            _hurtbox.Owner = this;
            _hurtbox.Configure(new Vector3(1f, 1.8f, 0.5f), new Vector3(0, 1f, 0));
        }

        void LoadMoves()
        {
            foreach (var m in MoveLibrary.LoadFromResources().moves)
                _moves[m.move_id] = m;
        }

        public MoveDefinition GetMove(string id) => _moves.TryGetValue(id, out var m) ? m : null;

        void Update()
        {
            if (_hitstopTimer > 0f)
            {
                _hitstopTimer -= Time.deltaTime;
                return;
            }

            StateMachine.Tick(Time.deltaTime);
            Shield.Tick(Time.deltaTime);
            Grab.Tick(Time.deltaTime);

            if (_grabbed && _grabbedBy != null) return;

            if (_hitstunTimer > 0f)
            {
                _hitstunTimer -= Time.deltaTime;
                if (_hitstunTimer <= 0f && IsGrounded)
                    StateMachine.Enter(FighterState.Idle);
                return;
            }

            if (IsPlayer) ReadInput();

            UpdateGrounded();
            UpdateFacing();
            UpdateMoveSim();
            UpdateStateFromMotion();
        }

        void FixedUpdate()
        {
            if (_grabbed || StateMachine.LocksMovement) return;
            if (!IsPlayer) return;
        }

        void ReadInput()
        {
            if (StateMachine.LocksActions && StateMachine.Current != FighterState.GrabHold) return;

            if (StateMachine.Current == FighterState.GrabHold)
            {
                if (Input.GetKeyDown(KeyCode.J) || Input.GetKeyDown(KeyCode.U))
                    Grab.ReleaseThrow();
                return;
            }

            var auraCharge = Input.GetKey(KeyCode.K) && Input.GetKey(KeyCode.L);
            if (auraCharge)
            {
                Aura.SetCharging(true);
                Aura.TickCharge(Time.deltaTime);
                return;
            }
            Aura.SetCharging(false);

            if (Input.GetKeyDown(KeyCode.J) && Aura.IsReady)
            {
                Aura.TryBurst(GetMove("aura_burst"));
                return;
            }

            if (Input.GetKey(KeyCode.L) && IsGrounded)
            {
                Shield.SetBlocking(true);
                return;
            }
            Shield.SetBlocking(false);

            if (Input.GetKeyDown(KeyCode.I))
            {
                StateMachine.Enter(FighterState.Dodge);
                _rb.velocity = new Vector3(Facing * 8f, _rb.velocity.y, 0);
                return;
            }

            if (Input.GetKeyDown(KeyCode.U)) StartMove(GetMove("grab"));
            if (Input.GetKeyDown(KeyCode.H)) StartMove(GetMove("heavy"));
            if (Input.GetKeyDown(KeyCode.K) && !auraCharge) StartMove(GetMove("neutral_special"));
            if (Input.GetKeyDown(KeyCode.J) && !Aura.IsReady) StartMove(GetMove("jab"));

            var mx = (Input.GetKey(KeyCode.D) ? 1f : 0f) - (Input.GetKey(KeyCode.A) ? 1f : 0f);
            if (!StateMachine.LocksMovement && Mathf.Abs(mx) > 0.01f)
            {
                var spd = Input.GetKey(KeyCode.LeftShift) ? 7f : 4.5f;
                _rb.velocity = new Vector3(mx * spd, _rb.velocity.y, 0);
                StateMachine.Enter(Mathf.Abs(mx) > 0.75f ? FighterState.Run : FighterState.Walk);
            }
            else if (IsGrounded && !MoveRunner.Active)
            {
                _rb.velocity = new Vector3(Mathf.MoveTowards(_rb.velocity.x, 0, 20f * Time.deltaTime), _rb.velocity.y, 0);
                if (Mathf.Abs(_rb.velocity.x) < 0.1f) StateMachine.Enter(FighterState.Idle);
            }

            if (Input.GetKeyDown(KeyCode.W) && IsGrounded)
            {
                _rb.velocity = new Vector3(_rb.velocity.x, 9f, 0);
                StateMachine.Enter(FighterState.Jump);
            }
        }

        public void ApplyMovementInput(float mx, bool run)
        {
            if (StateMachine.LocksMovement) return;
            var spd = run ? 7f : 4.5f;
            _rb.velocity = new Vector3(mx * spd, _rb.velocity.y, 0);
        }

        void UpdateGrounded()
        {
            IsGrounded = Physics.Raycast(transform.position + Vector3.up * 0.2f, Vector3.down, 1.3f);
            if (!IsGrounded && _rb.velocity.y < -0.1f && StateMachine.Current != FighterState.Hitstun)
                StateMachine.Enter(FighterState.Fall);
            if (IsGrounded && _rb.velocity.y <= 0.1f && StateMachine.Current == FighterState.Fall)
                StateMachine.Enter(FighterState.Land);
        }

        void UpdateFacing()
        {
            if (_rb.velocity.x > 0.2f) Facing = 1;
            else if (_rb.velocity.x < -0.2f) Facing = -1;
            var s = _body.localScale;
            s.x = Mathf.Abs(s.x) * Facing;
            _body.localScale = s;
        }

        void UpdateMoveSim()
        {
            _simAccum += Time.deltaTime;
            while (_simAccum >= 1f / MoveLibrary.SimFps)
            {
                _simAccum -= 1f / MoveLibrary.SimFps;
                MoveRunner.TickFrame();
            }
        }

        void UpdateStateFromMotion()
        {
            if (StateMachine.Current == FighterState.Land && StateMachine.StateTime > 0.08f)
                StateMachine.Enter(FighterState.Idle);
            if (StateMachine.Current == FighterState.ShieldStun && StateMachine.StateTime > 0.25f)
                StateMachine.Enter(FighterState.Idle);
            if (StateMachine.Current == FighterState.GrabWhiff && StateMachine.StateTime > 0.3f)
                StateMachine.Enter(FighterState.Idle);
            if (StateMachine.Current == FighterState.Dodge && StateMachine.StateTime > 0.15f)
                StateMachine.Enter(FighterState.Idle);
        }

        public void StartMove(MoveDefinition move)
        {
            if (move == null || MoveRunner.Active) return;
            _hitThisMove.Clear();
            MoveRunner.Start(move);
            if (move.is_grab) StateMachine.Enter(FighterState.GrabStartup);
            else if (move.is_aura_burst) StateMachine.Enter(FighterState.AuraBurstStartup);
            else StateMachine.Enter(FighterState.AttackStartup);
        }

        void OnPhaseChanged(string phase)
        {
            if (phase == "active")
            {
                var m = MoveRunner.Move;
                if (m.is_grab)
                {
                    StateMachine.Enter(FighterState.GrabActive);
                    TryGrabConnect(Dummy, out var tag);
                    LastHitResult = tag;
                    if (tag != "GRAB") Grab.Whiff();
                }
                else
                {
                    StateMachine.Enter(m.is_aura_burst ? FighterState.AuraBurstActive : FighterState.AttackActive);
                    ApplyHitboxFromMove(m);
                }
            }
            else if (phase == "recovery")
            {
                _hitbox.SetActiveHitbox(false);
                StateMachine.Enter(FighterState.AttackRecovery);
            }
        }

        void OnMoveEnded()
        {
            _hitbox.SetActiveHitbox(false);
            StateMachine.Enter(FighterState.Idle);
        }

        void ApplyHitboxFromMove(MoveDefinition m)
        {
            var off = new Vector3(m.hitbox_offset.x * Facing, m.hitbox_offset.y, 0);
            _hitbox.Configure(new Vector3(m.hitbox_size.x, m.hitbox_size.y, 0.5f), off);
            _hitbox.SetActiveHitbox(true);
        }

        public void TryHit(FighterController defender)
        {
            if (!MoveRunner.IsActivePhase || defender == null) return;
            if (_hitThisMove.Contains(defender)) return;
            _hitThisMove.Add(defender);
            var move = MoveRunner.Move;
            HitResolver.Resolve(this, defender, move, out var tag);
            LastHitResult = tag;
            if (tag == "HIT") ComboCount++;
        }

        public void TryGrabConnect(FighterController target, out string tag)
        {
            tag = "GRAB_WHIFF";
            Grab.TryConnect(target, out var ok);
            tag = ok ? "GRAB" : "GRAB_WHIFF";
        }

        public void ApplyHit(float dmg, Vector2 launch, float hitstun, float hitstop)
        {
            DamagePercent += dmg;
            _rb.velocity = new Vector3(launch.x, launch.y, 0);
            _hitstunTimer = hitstun;
            ComboCount = 0;
            StateMachine.Enter(launch.y > 8f ? FighterState.Launched : FighterState.Hitstun);
        }

        public void ApplyHitstop(float t) => _hitstopTimer = t;

        public void EnterShieldStun() => StateMachine.Enter(FighterState.ShieldStun);

        public void OnGrabbed(FighterController by)
        {
            _grabbed = true;
            _grabbedBy = by;
            _rb.velocity = Vector3.zero;
            StateMachine.Enter(FighterState.GrabHold);
        }

        public void OnGrabReleased()
        {
            _grabbed = false;
            _grabbedBy = null;
        }

        public void OnThrown(FighterController by)
        {
            _grabbed = false;
            _grabbedBy = null;
            var throwMove = by.GetMove("throw");
            if (throwMove != null)
                HitResolver.Resolve(by, this, throwMove, out var tag);
            LastHitResult = "THROW";
        }

        public void ResetFighter(Vector3 pos)
        {
            transform.position = pos;
            _rb.velocity = Vector3.zero;
            DamagePercent = 0f;
            ComboCount = 0;
            Shield.ResetShield();
            Aura.Clear();
            Grab.Clear();
            _hitstunTimer = 0f;
            MoveRunner.Cancel();
            StateMachine.Enter(FighterState.Idle);
            LastHitResult = "RESET";
        }

        public void SetDebugBoxes(bool hit, bool hurt)
        {
            if (hit && MoveRunner.IsActivePhase) _hitbox.SetActiveHitbox(true);
            _hurtbox.SetDebugVisible(hurt);
        }
    }
}
