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

        public const float WalkSpeed = 4.5f;
        public const float RunSpeed = 7f;
        public const float JumpVelocity = 9f;
        public const float FastFallVelocity = -14f;
        public const int MaxJumps = 2;

        public float DamagePercent { get; private set; }
        public int ComboCount { get; private set; }
        public string LastHitResult { get; private set; } = "—";
        public bool IsGrounded { get; private set; }
        public bool IsGrabbed => _grabbed;
        public Vector3 Velocity => _rb.linearVelocity;
        public Hitbox ActiveHitbox => _hitbox;

        public FighterStateMachine StateMachine { get; private set; }
        public MoveRunner MoveRunner { get; private set; }
        public ShieldController Shield { get; private set; }
        public GrabController Grab { get; private set; }
        public AuraController Aura { get; private set; }

        Rigidbody _rb;
        Hitbox _hitbox;
        Hurtbox _hurtbox;
        Transform _body;
        Transform _facingIndicator;
        GameObject _shieldBubble;
        GameObject _auraGlow;
        Dictionary<string, MoveDefinition> _moves = new Dictionary<string, MoveDefinition>();
        float _hitstunTimer;
        float _hitstopTimer;
        float _simAccum;
        int _jumpsUsed;
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
            _rb.collisionDetectionMode = CollisionDetectionMode.Continuous;

            // Solid body collider — hitbox/hurtbox children are triggers only.
            var capsule = gameObject.AddComponent<CapsuleCollider>();
            capsule.center = new Vector3(0, 1f, 0);
            capsule.height = 2f;
            capsule.radius = 0.35f;

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
            _body.name = "Body (PROXY — NOT FINAL ART)";
            _body.SetParent(transform, false);
            _body.localPosition = new Vector3(0, 1f, 0);
            Destroy(_body.GetComponent<Collider>());
            _body.GetComponent<Renderer>().material.color = IsPlayer ? new Color(0.9f, 0.35f, 0.2f) : new Color(0.3f, 0.5f, 0.9f);

            // Small nose cube so facing direction reads on a symmetric capsule.
            _facingIndicator = GameObject.CreatePrimitive(PrimitiveType.Cube).transform;
            _facingIndicator.name = "FacingIndicator";
            Destroy(_facingIndicator.GetComponent<Collider>());
            _facingIndicator.SetParent(transform, false);
            _facingIndicator.localScale = new Vector3(0.25f, 0.15f, 0.15f);
            _facingIndicator.localPosition = new Vector3(0.45f, 1.5f, 0);
            _facingIndicator.GetComponent<Renderer>().material.color = Color.white;

            _shieldBubble = CombatVisuals.MakeSphere(transform, "ShieldBubble", new Color(0.3f, 0.9f, 1f, 0.35f), 2.2f, new Vector3(0, 1f, 0));
            _shieldBubble.SetActive(false);

            _auraGlow = CombatVisuals.MakeSphere(transform, "AuraGlow", new Color(1f, 0.55f, 0.1f, 0.3f), 2.6f, new Vector3(0, 1f, 0));
            _auraGlow.SetActive(false);
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
                _hitstopTimer -= Time.unscaledDeltaTime;
                return;
            }

            StateMachine.Tick(Time.deltaTime);
            Shield.Tick(Time.deltaTime);
            Grab.Tick(Time.deltaTime);
            UpdateFeedbackVisuals();

            if (_grabbed && _grabbedBy != null) return;

            UpdateGrounded();

            if (_hitstunTimer > 0f)
            {
                _hitstunTimer -= Time.deltaTime;
                if (_hitstunTimer <= 0f)
                    StateMachine.Enter(IsGrounded ? FighterState.Idle : FighterState.Fall);
                return;
            }

            if (IsPlayer) ReadInput();

            UpdateFacing();
            UpdateMoveSim();
            UpdateStateFromMotion();
        }

        void ReadInput()
        {
            if (Time.timeScale == 0f) return;

            var st = StateMachine.Current;

            // Grab hold: J or U throws the held target.
            if (st == FighterState.GrabHold)
            {
                if (Input.GetKeyDown(KeyCode.J) || Input.GetKeyDown(KeyCode.U))
                    Grab.ReleaseThrow();
                return;
            }

            // Shield hold: release L to drop shield; K+L transitions to aura charge.
            if (st == FighterState.ShieldHold)
            {
                if (Input.GetKey(KeyCode.K) && Input.GetKey(KeyCode.L))
                {
                    Shield.SetBlocking(false);
                    Aura.SetCharging(true);
                    return;
                }
                if (!Input.GetKey(KeyCode.L) || !IsGrounded)
                {
                    Shield.SetBlocking(false);
                    StateMachine.Enter(FighterState.Idle);
                }
                return;
            }

            // Aura charge: keep holding K+L to fill, release to stop.
            if (st == FighterState.AuraCharge || st == FighterState.AuraReady)
            {
                if (Input.GetKeyDown(KeyCode.J) && Aura.IsReady)
                {
                    Aura.SetCharging(false);
                    Aura.TryBurst(GetMove("aura_burst"));
                    return;
                }
                if (Input.GetKey(KeyCode.K) && Input.GetKey(KeyCode.L))
                {
                    Aura.TickCharge(Time.deltaTime);
                }
                else
                {
                    Aura.SetCharging(false);
                    StateMachine.Enter(FighterState.Idle);
                }
                return;
            }

            if (StateMachine.LocksActions) return;

            // Ensure shield drops if L was released while in a transitional state.
            if (Shield.IsBlocking && !Input.GetKey(KeyCode.L)) Shield.SetBlocking(false);

            if (Input.GetKey(KeyCode.K) && Input.GetKey(KeyCode.L) && IsGrounded)
            {
                Aura.SetCharging(true);
                return;
            }

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

            if (Input.GetKeyDown(KeyCode.I))
            {
                StateMachine.Enter(FighterState.Dodge);
                _rb.linearVelocity = new Vector3(Facing * 8f, _rb.linearVelocity.y, 0);
                return;
            }

            if (Input.GetKeyDown(KeyCode.U)) { StartMove(GetMove("grab")); return; }
            if (Input.GetKeyDown(KeyCode.H)) { StartMove(GetMove("heavy")); return; }
            if (Input.GetKeyDown(KeyCode.K)) { StartMove(GetMove("neutral_special")); return; }
            if (Input.GetKeyDown(KeyCode.J)) { StartMove(GetMove("jab")); return; }

            var mx = (Input.GetKey(KeyCode.D) ? 1f : 0f) - (Input.GetKey(KeyCode.A) ? 1f : 0f);
            if (!StateMachine.LocksMovement && Mathf.Abs(mx) > 0.01f)
            {
                var run = Input.GetKey(KeyCode.LeftShift);
                _rb.linearVelocity = new Vector3(mx * (run ? RunSpeed : WalkSpeed), _rb.linearVelocity.y, 0);
                if (IsGrounded)
                    StateMachine.Enter(run ? FighterState.Run : FighterState.Walk);
            }
            else if (IsGrounded && !MoveRunner.Active)
            {
                _rb.linearVelocity = new Vector3(Mathf.MoveTowards(_rb.linearVelocity.x, 0, 20f * Time.deltaTime), _rb.linearVelocity.y, 0);
                if (Mathf.Abs(_rb.linearVelocity.x) < 0.1f &&
                    (StateMachine.Current == FighterState.Walk || StateMachine.Current == FighterState.Run))
                    StateMachine.Enter(FighterState.Idle);
            }

            if (Input.GetKeyDown(KeyCode.W))
            {
                if (IsGrounded)
                {
                    _jumpsUsed = 1;
                    _rb.linearVelocity = new Vector3(_rb.linearVelocity.x, JumpVelocity, 0);
                    StateMachine.Enter(FighterState.Jump);
                }
                else if (_jumpsUsed < MaxJumps)
                {
                    _jumpsUsed++;
                    _rb.linearVelocity = new Vector3(_rb.linearVelocity.x, JumpVelocity * 0.95f, 0);
                    StateMachine.Enter(FighterState.DoubleJump);
                }
            }

            // Fast fall: press S while airborne and not rising fast.
            if (Input.GetKey(KeyCode.S) && !IsGrounded && _rb.linearVelocity.y < 2f)
            {
                _rb.linearVelocity = new Vector3(_rb.linearVelocity.x, FastFallVelocity, 0);
                StateMachine.Enter(FighterState.FastFall);
            }
        }

        void UpdateGrounded()
        {
            IsGrounded = Physics.Raycast(transform.position + Vector3.up * 0.2f, Vector3.down, 0.35f,
                Physics.DefaultRaycastLayers, QueryTriggerInteraction.Ignore);
            if (IsGrounded) _jumpsUsed = 0;

            var st = StateMachine.Current;
            if (!IsGrounded && _rb.linearVelocity.y < -0.1f &&
                (st == FighterState.Idle || st == FighterState.Walk || st == FighterState.Run ||
                 st == FighterState.Jump || st == FighterState.DoubleJump || st == FighterState.Launched))
                StateMachine.Enter(FighterState.Fall);
            if (IsGrounded && _rb.linearVelocity.y <= 0.1f &&
                (st == FighterState.Fall || st == FighterState.FastFall))
                StateMachine.Enter(FighterState.Land);
        }

        void UpdateFacing()
        {
            if (!StateMachine.LocksMovement)
            {
                if (_rb.linearVelocity.x > 0.2f) Facing = 1;
                else if (_rb.linearVelocity.x < -0.2f) Facing = -1;
            }
            var p = _facingIndicator.localPosition;
            p.x = 0.45f * Facing;
            _facingIndicator.localPosition = p;
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
            var st = StateMachine.Current;
            if (st == FighterState.Land && StateMachine.StateTime > 0.08f)
                StateMachine.Enter(FighterState.Idle);
            if (st == FighterState.ShieldStun && StateMachine.StateTime > 0.25f)
                StateMachine.Enter(FighterState.Idle);
            if (st == FighterState.GrabWhiff && StateMachine.StateTime > 0.3f)
                StateMachine.Enter(FighterState.Idle);
            if (st == FighterState.ThrowRelease && StateMachine.StateTime > 0.3f)
                StateMachine.Enter(FighterState.Idle);
            if (st == FighterState.Dodge && StateMachine.StateTime > 0.15f)
                StateMachine.Enter(FighterState.Idle);
        }

        void UpdateFeedbackVisuals()
        {
            var blocking = Shield.IsBlocking;
            if (_shieldBubble.activeSelf != blocking) _shieldBubble.SetActive(blocking);
            if (blocking)
            {
                var t = Mathf.Clamp01(Shield.Health / Shield.MaxHealth);
                _shieldBubble.transform.localScale = Vector3.one * Mathf.Lerp(1.1f, 2.2f, t);
            }

            var aura = Aura.Charging || Aura.IsReady;
            if (_auraGlow.activeSelf != aura) _auraGlow.SetActive(aura);
            if (aura)
            {
                var t = Mathf.Clamp01(Aura.Meter / 100f);
                var pulse = Aura.IsReady ? 1f + Mathf.PingPong(Time.time * 2f, 0.3f) : 1f;
                _auraGlow.transform.localScale = Vector3.one * Mathf.Lerp(1.2f, 2.6f, t) * pulse;
            }
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
                    TryGrabConnect(IsPlayer ? Dummy : Player, out var tag);
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
                if (StateMachine.Current == FighterState.GrabHold) return;
                var m = MoveRunner.Move;
                if (m != null && m.is_grab) return;
                StateMachine.Enter(m != null && m.is_aura_burst ? FighterState.AuraBurstRecovery : FighterState.AttackRecovery);
            }
        }

        void OnMoveEnded()
        {
            _hitbox.SetActiveHitbox(false);
            if (StateMachine.Current == FighterState.GrabHold) return;
            if (StateMachine.Current == FighterState.Hitstun || StateMachine.Current == FighterState.Launched) return;
            StateMachine.Enter(FighterState.Idle);
        }

        void ApplyHitboxFromMove(MoveDefinition m)
        {
            var off = new Vector3(m.hitbox_offset.x * Facing, m.hitbox_offset.y + 1f, 0);
            _hitbox.Configure(new Vector3(m.hitbox_size.x, m.hitbox_size.y, 0.6f), off);
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
            Grab.TryConnect(target, out var ok);
            tag = ok ? "GRAB" : "GRAB_WHIFF";
        }

        public void ApplyHit(float dmg, Vector2 launch, float hitstun, float hitstop)
        {
            DamagePercent += dmg;
            MoveRunner.Cancel();
            _hitbox.SetActiveHitbox(false);
            Shield.SetBlocking(false);
            _rb.linearVelocity = new Vector3(launch.x, launch.y, 0);
            _hitstunTimer = hitstun;
            _hitstopTimer = hitstop;
            ComboCount = 0;
            StateMachine.Enter(launch.y > 8f ? FighterState.Launched : FighterState.Hitstun);
        }

        public void ApplyHitstop(float t) => _hitstopTimer = t;

        public void EnterShieldStun() => StateMachine.Enter(FighterState.ShieldStun);

        public void OnGrabbed(FighterController by)
        {
            _grabbed = true;
            _grabbedBy = by;
            MoveRunner.Cancel();
            _rb.linearVelocity = Vector3.zero;
            _rb.isKinematic = true;
            StateMachine.Enter(FighterState.GrabHold);
        }

        public void OnGrabReleased()
        {
            _grabbed = false;
            _grabbedBy = null;
            _rb.isKinematic = false;
            StateMachine.Enter(FighterState.Idle);
        }

        public void OnThrown(FighterController by)
        {
            _grabbed = false;
            _grabbedBy = null;
            _rb.isKinematic = false;
            var throwMove = by.GetMove("throw");
            if (throwMove != null)
                HitResolver.Resolve(by, this, throwMove, out _);
            by.LastHitResult = "THROW";
            LastHitResult = "THROWN";
        }

        public void ResetFighter(Vector3 pos)
        {
            transform.position = pos;
            _rb.linearVelocity = Vector3.zero;
            DamagePercent = 0f;
            ComboCount = 0;
            Shield.ResetShield();
            Aura.Clear();
            Grab.Clear();
            _grabbed = false;
            _grabbedBy = null;
            _rb.isKinematic = false;
            _hitstunTimer = 0f;
            _hitstopTimer = 0f;
            _jumpsUsed = 0;
            MoveRunner.Cancel();
            _hitbox.SetActiveHitbox(false);
            StateMachine.Enter(FighterState.Idle);
            LastHitResult = "RESET";
        }

        public void SetOverlay(bool hitboxes, bool hurtboxes)
        {
            _hitbox.SetDebugVisible(hitboxes);
            _hurtbox.SetDebugVisible(hurtboxes);
        }
    }
}
