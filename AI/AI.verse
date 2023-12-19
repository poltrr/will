using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { FiniteStateMachineByPoltrr }
using { NavigationMeshSystemByPoltrr }

AI<public> := module:
    Base<public> := module:
        base<public> := class(creative_device):
            # Attributes #

            # Creative prop manipulated by the agent.
            @editable Prop<protected> : creative_prop = creative_prop{}

            # Meters traversed per second.
            @editable Speed<protected> : type{t : float where t > 0.0} = 1.0

            # Methods #

            # Rotate `Prop` to `Radians` in a span of `Seconds`.
            RotateTo<public>(Radians : float, ?Seconds : float = 0.0)<suspends> : rotation =
                Translation := Prop.GetTransform().Translation
                Rotation := MakeRotation(vector3{Z := -1.0}, Radians)

                # Rotate instantly if `Seconds` <= 0.0.
                if (Seconds <= 0.0):
                    if (Prop.TeleportTo[Translation, Rotation]) {}
                # Rotate over time.
                else:
                    Prop.MoveTo(Translation, Rotation, Seconds)
                
                Rotation
            
            # Rotate `RotationProp` in direction to `Target`, in a span of `Seconds`.
            RotateTowards<public>(Target : vector3, Seconds : float)<suspends> : rotation =
                VectorToTarget : vector3 = Target - Prop.GetTransform().Translation
                RadiansToTarget : float = ArcTan(VectorToTarget.X, VectorToTarget.Y)
                RotateTo(RadiansToTarget, ?Seconds := Seconds)
            
            # Move `Prop` to `Target`.
            MoveTo<public>(
                Target : vector3,
                ?MetersPerSecond : float = Speed,
                ?MaxSeconds : float = Inf,
                ?RadiansPerSecond : float = PiFloat
            )<suspends> : void =
                Translation := Prop.GetTransform().Translation
                DistanceToTarget := Distance(Translation, Target)
                
                if (Prop.IsValid[]; DistanceToTarget > 0.0):
                    # Seconds `Target` will take to be reached.
                    SecondsToTarget := DistanceToTarget / (MetersPerSecond * 100.0)
                    # Vector in direction of `Target`.
                    VectorToTarget := Target - Translation
                    
                    if (UnitVectorToTarget := VectorToTarget.MakeUnitVector[]; SecondsToTarget > 0.0):
                        # Seconds the entire movement will take.
                        Seconds := Clamp(SecondsToTarget, 0.0, MaxSeconds)
                        # The actual target that `Prop` will move to.
                        ClampedTarget := Translation + UnitVectorToTarget * (MetersPerSecond * Seconds * 100.0)
                        # Angle in randians of `Prop`.
                        Radians : float = Prop.GetTransform().Rotation.GetAngle()
                        # Angle in radians, in direction of `Target`.
                        RadiansToTarget : float = ArcTan(VectorToTarget.X, VectorToTarget.Y)
                        # The actual rotation that `Prop` will move to.
                        Rotation := MakeRotation(vector3{Z := -1.0}, RadiansToTarget)
                        # Radians between the current and target angle.
                        RadianDistance : float = Abs(RadiansToTarget - Radians)
                        # Seconds `CompleteRotation` will take to be reached.
                        SecondsToCompleteRotation : float =
                            if (RadiansPerSecond <= 0.0 or not RadiansPerSecond.IsFinite[])
                            then 0.0
                            else RadianDistance / RadiansPerSecond
                        # Distance to the actual target.
                        DistanceToClampedTarget := Distance(Translation, ClampedTarget)
                        # Seconds the first part of the movement will take (which handles rotation).
                        SecondsToRotate := Clamp(SecondsToCompleteRotation, 0.0, Seconds)
                        # 0.0: The rotation is immediate.
                        # 0.0 < x < 1.0: The rotation takes less time than the entire movement.
                        # 1.0: The rotation takes the same time or more as the entire movement.
                        FirstTargetRatio := Clamp(SecondsToRotate / Seconds, 0.0, 1.0)
                        # Translation the `Prop` will reach after completing the rotation.
                        # If the complete rotation takes more time than `Seconds`, then `FirstTarget` will be equal
                        #   to `Target`.
                        FirstTarget := Lerp(Translation, ClampedTarget, FirstTargetRatio)
                        # The actual radians that `Prop` will rotate to.
                        ClampedRadians :=
                            if (SecondsToRotate > 0.0)
                            then Lerp(Radians, RadiansToTarget, Clamp(Seconds / SecondsToRotate, 0.0, 1.0))
                            else Radians
                        # The actual rotation that `Prop` will move to.
                        ClampedRotation := MakeRotation(vector3{Z := -1.0}, ClampedRadians)

                        # Execute first part of the movement to rotate.
                        if (SecondsToRotate > 0.0):
                            Prop.MoveTo(FirstTarget, ClampedRotation, SecondsToRotate)
                        # Rotate immediately.
                        else if (Prop.TeleportTo[Translation, ClampedRotation]) {}

                        # Finish movement if remaining.
                        if (RemainingSeconds := Seconds - SecondsToRotate; RemainingSeconds > 0.0):
                            Prop.MoveTo(ClampedTarget, ClampedRotation, RemainingSeconds)
            
            # Teleport `Prop` to `Target`.
            TeleportTo<public>(Target : vector3) : void =
                Rotation := Prop.GetTransform().Rotation
                if (Prop.IsValid[]; Prop.TeleportTo[Target, Rotation]) {}

            GetTransform<override>()<transacts> : transform = Prop.GetTransform()
            
            GetProp<public>()<transacts> : creative_prop = Prop

            GetSpeed<public>()<transacts> : type{t : float where t > 0.0} = Speed
    # Unnamed ai.
    Unnamed<public> := module:
        Behavior<internal> := module:
            state_base<internal> := class(state):
                # Attributes #

                # Finite state machine that controls this state.
                var MaybeOwner<private> : ?fsm = false

                # Agent to control.
                var MaybeUnnamedAgent<private> : ?Agent.unnamed = false

                # Methods #

                # Initialize state by injecting dependencies:
                Initialize<public>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    set MaybeOwner = option{Owner}
                    set MaybeUnnamedAgent = option{UnnamedAgent}

                Enter<protected>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void = {}
            
                Update<protected>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base = false
            
                Exit<protected>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void = {}

                # Wrapper for `Enter<protected>(Owner : fsm)`. Do not override any further.
                Enter<override>() : void =
                    if (Owner := MaybeOwner?; UnnamedAgent := MaybeUnnamedAgent?):
                        Enter(Owner, UnnamedAgent)
            
                # Wrapper for `Update<protected>(Owner : fsm)`. Do not override any further.
                Update<override>()<suspends> : ?state_base =
                    if (Owner := MaybeOwner?; UnnamedAgent := MaybeUnnamedAgent?):
                        MaybeNextState := Update(Owner, UnnamedAgent)
                        if (NextState := MaybeNextState?):
                            return option{NextState}
                    false
                
                # Wrapper for `Exit<protected>(Owner : fsm)`. Do not override any further.
                Exit<override>() : void =
                    if (Owner := MaybeOwner?; UnnamedAgent := MaybeUnnamedAgent?):
                        Exit(Owner, UnnamedAgent)
            
            state_idle<internal> := class(state_base):
                # Methods #

                # Return `state_patrol` when `IdleDuration` seconds has passed.
                AsyncWaitTime<private>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    Sleep(UnnamedAgent.GetIdleDuration())
                    option{Owner.GetStatePatrol()}

                # Return `state_chase_player` when a player is seen.
                AsyncWaitToSeePlayer<private>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    loop:
                        if (UnnamedAgent.GetTargetedPlayer[]):
                            break
                        Sleep(0.0)
                    option{Owner.GetStateChasePlayer()}
                
                Enter<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    Print("Entered `Idle`.")
                    UnnamedAgent.GetIdleSequence().Play()

                Update<override>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    race:
                        AsyncWaitTime(Owner, UnnamedAgent)
                        AsyncWaitToSeePlayer(Owner, UnnamedAgent)
                
                Exit<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    UnnamedAgent.GetIdleSequence().Stop()
            
            state_patrol<internal> := class(state_base):
                # Attributes #

                # Index of the next patrol target.
                var PatrolIndex : int = 0
                
                # Methods #

                # Return `state_idle` when the next patrol point is reached.
                # Else, return `false` to update state again.
                AsyncGoToNextPatrolPoint<private>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    PatrolPoints := UnnamedAgent.GetPatrolPoints()
                    # Move to next patrol point, and update index.
                    if (NextTarget := PatrolPoints[PatrolIndex]):
                        Translation := UnnamedAgent.GetTransform().Translation
                        # Calculate next position to go to, to reach the patrol point.
                        if:
                            Navmesh := GetGameManager[].GetNavmesh()
                            StartTriangle := Navmesh.GetClosestTriangleToPoint[Translation]
                            EndTriangle := Navmesh.GetClosestTriangleToPoint[NextTarget]
                            Path := Navmesh.GetShortestPath[StartTriangle, EndTriangle]
                            Step := Navmesh.GetFirstSmoothStep[Path, Translation, NextTarget]
                        then:
                            if (First := Path[0]; Second := Path[1]):
                            UnnamedAgent.MoveTo(Step.Translation)
                            # Once the patrol point is reached, move on to the next one.
                            if:
                                DistanceXY(Step.Translation, NextTarget) < UnnamedAgent.GetMovementTolerance()
                                NextIndex := Mod[PatrolIndex + 1, PatrolPoints.Length]
                            then:
                                set PatrolIndex = NextIndex
                                return option{Owner.GetStateIdle()}
                    false
                
                # Return `state_chase_player` when a player is seen.
                AsyncWaitToSeePlayer<private>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    loop:
                        if (UnnamedAgent.GetTargetedPlayer[]):
                            break
                        Sleep(0.0)
                    option{Owner.GetStateChasePlayer()}

                Enter<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    Print("Entered `Patrol`.")
                    UnnamedAgent.GetPatrolSequence().Play()

                Update<override>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    # Go towards the next patrol point.
                    rush:
                        AsyncGoToNextPatrolPoint(Owner, UnnamedAgent)
                        AsyncWaitToSeePlayer(Owner, UnnamedAgent)
                
                Exit<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    UnnamedAgent.GetPatrolSequence().Stop()
            
            state_chase_player<internal> := class(state_base):
                # Attributes #

                # Last `Player` translation recorded.
                var MaybeLastKnownTranslation : ?vector3 = false
                
                # Methods #

                # Move towards the `Player`.
                AsyncGoToPlayer<private>(Owner : fsm, UnnamedAgent : Agent.unnamed, Player : player)<suspends> : ?state_base =
                    Translation := UnnamedAgent.GetTransform().Translation
                    if (FortCharacter := Player.GetFortCharacter[]):
                        PlayerTranslation := FortCharacter.GetTransform().Translation
                        # Calculate next position to go to, to reach the player.
                        if:
                            Navmesh := GetGameManager[].GetNavmesh()
                            StartTriangle := Navmesh.GetClosestTriangleToPoint[Translation]
                            EndTriangle := Navmesh.GetClosestTriangleToPoint[PlayerTranslation]
                            Path := Navmesh.GetShortestPath[StartTriangle, EndTriangle]
                            Step := Navmesh.GetFirstSmoothStep[Path, Translation, PlayerTranslation]
                        then:
                            # Store as `LastKnownTranslation` once we assure the `Player` is inside the mesh.
                            set MaybeLastKnownTranslation = option{PlayerTranslation}
                            
                            Speed := UnnamedAgent.GetSpeed() * UnnamedAgent.GetChaseSpeedMultiplier()
                            UpdateRate := UnnamedAgent.GetChaseUpdateRate()
                            UnnamedAgent.MoveTo(Step.Translation, ?MetersPerSecond := Speed, ?MaxSeconds := UpdateRate)
                    false

                # Return `false` when another player is seen closer, to update again.
                AsyncWaitForAnotherPlayer<private>(
                    Owner : fsm,
                    UnnamedAgent : Agent.unnamed,
                    Player : player
                )<suspends> : ?state_base =
                    loop:
                        if (CurrentPlayer := UnnamedAgent.GetTargetedPlayer[]; Player <> CurrentPlayer):
                            break
                        Sleep(0.0)
                    false
                
                # Return `state_idle` when the player's last known location is rached.
                AsyncGoToLastKnownTranslation<private>(
                    Owner : fsm,
                    UnnamedAgent : Agent.unnamed
                )<suspends> : ?state_base =
                    if:
                        LastKnownTranslation := MaybeLastKnownTranslation?
                        Translation := UnnamedAgent.GetTransform().Translation
                        Navmesh := GetGameManager[].GetNavmesh()
                        StartTriangle := Navmesh.GetClosestTriangleToPoint[Translation]
                        EndTriangle := Navmesh.GetClosestTriangleToPoint[LastKnownTranslation]
                        Path := Navmesh.GetShortestPath[StartTriangle, EndTriangle]
                        Step := Navmesh.GetFirstSmoothStep[Path, Translation, LastKnownTranslation]
                    then:
                        Speed := UnnamedAgent.GetSpeed() * UnnamedAgent.GetChaseSpeedMultiplier()
                        UnnamedAgent.MoveTo(Step.Translation, ?MetersPerSecond := Speed)
                        # Once the `LastKnownTranslation` is reached, return `state_idle`.
                        if:
                            ProjectedLastKnownTranslation := vector3:
                                X := Step.Translation.X
                                Y := Step.Translation.Y
                                Z := Navmesh.GetClosestPointOnTriangle[EndTriangle, LastKnownTranslation].Z
                            DistanceXY(Step.Translation, ProjectedLastKnownTranslation) < UnnamedAgent.GetMovementTolerance()
                        then:
                            option{Owner.GetStateIdle()}
                        else:
                            false
                    else:
                        option{Owner.GetStateIdle()}
                
                # Return `false` when any player enters sight.
                AsyncWaitForAnyPlayer<private>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    loop:
                        if (UnnamedAgent.GetTargetedPlayer[]):
                            break
                        Sleep(0.0)
                    false

                Enter<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    UnnamedAgent.GetChasePlayerSequence().Play()

                Update<override>(Owner : fsm, UnnamedAgent : Agent.unnamed)<suspends> : ?state_base =
                    # Chase the closest player in sight.
                    # If player is lost sight of, continue to go to their last known position.
                    if (Player := UnnamedAgent.GetTargetedPlayer[]):
                        rush:
                            AsyncGoToPlayer(Owner, UnnamedAgent, Player)
                            AsyncWaitForAnotherPlayer(Owner, UnnamedAgent, Player)
                    # Return `state_idle` when a player is lost sight of.
                    else:
                        rush:
                            AsyncGoToLastKnownTranslation(Owner, UnnamedAgent)
                            AsyncWaitForAnyPlayer(Owner, UnnamedAgent)
                
                Exit<override>(Owner : fsm, UnnamedAgent : Agent.unnamed) : void =
                    UnnamedAgent.GetChasePlayerSequence().Stop()
            
            fsm<public> := class(finite_state_machine):
                # Attributes #

                StateIdle<private> : state_idle = state_idle{}

                StatePatrol<private> : state_patrol = state_patrol{}

                StateChasePlayer<private> : state_chase_player = state_chase_player{}
                
                # Methods #

                # Start the finite state machine.
                Start<public>(UnnamedAgent : Agent.unnamed) : void =
                    StateIdle.Initialize(Self, UnnamedAgent)
                    StatePatrol.Initialize(Self, UnnamedAgent)
                    StateChasePlayer.Initialize(Self, UnnamedAgent)

                    Start(StateIdle)
                
                GetStateIdle<internal>()<transacts> : state_idle = StateIdle

                GetStatePatrol<internal>()<transacts> : state_patrol = StatePatrol

                GetStateChasePlayer<internal>()<transacts> : state_chase_player = StateChasePlayer
        
        Agent<public> := module:
            unnamed_advanced_settings<internal> := class<concrete>:
                # Tolerance, in meters, to reach a destination after a movement.
                @editable MovementTolerance<public> : type{t : float where t > 0.0} = 0.1

                # Idle #
                
                # Cinematic sequencer for the idle animation.
                @editable IdleSequence<public> : cinematic_sequence_device = cinematic_sequence_device{}
                
                # Seconds the agent will stay in idle.
                @editable IdleDuration<public> : type{t : float where t >= 0.0} = 5.0

                # Patrol #
                
                # Cinematic sequencer for the patrol animation.
                @editable PatrolSequence<public> : cinematic_sequence_device = cinematic_sequence_device{}
                
                # Translations the agent will patrol to.
                @editable PatrolPoints<public> : []vector3 = array{}

                # Chase Player #

                # Cinematic sequencer for the chase_player animation.
                @editable ChasePlayerSequence<public> : cinematic_sequence_device = cinematic_sequence_device{}

                # Multiplier applied to `Speed` when chasing a player.
                @editable ChaseSpeedMultiplier<public> : type{t : float where t > 0.0} = 2.0

                # Delay between each update when chasing the player.
                # The lower the number, the more reponsive and resource-intensive it will be.
                @editable ChaseUpdateRate<public> : type{t : float where t >= 0.0} = 0.1
            
            unnamed<public> := class(Base.base):
                # Attributes #

                # Perception trigger to detect a player in sight.
                @editable PerceptionTrigger<private> : perception_trigger_device = perception_trigger_device{}
                
                # Advanced settings.
                @editable Advanced<private> : unnamed_advanced_settings = unnamed_advanced_settings{}

                # Players seen by the agent.
                var PlayersInSight<private> : []player = array{}

                # Latest targeted player by the agent.
                var MaybeTargetedPlayer<private> : ?player = false

                # Finite state machine.
                FSM<private> : Behavior.fsm = Behavior.fsm{}

                # Methods #

                OnBegin<override>()<suspends> : void =
                    # Subscribe to events.
                    PerceptionTrigger.DeviceSeesAgentEvent.Subscribe(OnPerceptionTriggerDeviceSeesAgent)
                    PerceptionTrigger.DeviceLosesSightOfAgentEvent.Subscribe(OnPerceptionTriggerDeviceLosessSightOfAgent)

                # Start the agent, at the `InitialTranslation`.
                Start<public>(InitialTranslation : vector3) : void =
                    TeleportTo(InitialTranslation)
                    FSM.Start(Self)
                
                # Add `InAgent` to `PlayersInSight` if they are in sight, and inside the navmesh area.
                OnPerceptionTriggerDeviceSeesAgent<private>(InAgent : agent) : void =
                    if (Player := player[InAgent]):
                        set PlayersInSight += array{Player}

                # Remove `InAgent` from `PlayersInSight` if sight is lost.
                OnPerceptionTriggerDeviceLosessSightOfAgent<private>(InAgent : agent) : void =
                    if (Player := player[InAgent]):
                        set PlayersInSight = PlayersInSight.RemoveAllElements(Player)
                
                # Return the current player to target.
                GetTargetedPlayer<public>()<transacts><decides> : player =
                    var MaybePlayer : ?player = false
                    
                    loop:
                        # Check if `PreviousTargetedPlayer` is still valid.
                        if:
                            PreviousTargetedPlayer := MaybeTargetedPlayer?
                            # `PreviousTargetedPlayer` still on sight.
                            PlayersInSight.Find[PreviousTargetedPlayer]
                            Translation := PreviousTargetedPlayer.GetFortCharacter[].GetTransform().Translation
                            Navmesh := GetGameManager[].GetNavmesh()
                            # `PreviousTargetedPlayer` still inside the navmesh.
                            Navmesh.GetClosestTriangleToPoint[Translation]
                        then:
                            set MaybePlayer = option{PreviousTargetedPlayer}
                            break
                        # Check for a valid player in `PlayersInSight`.
                        for (Player : PlayersInSight):
                            if:
                                Translation := Player.GetFortCharacter[].GetTransform().Translation
                                Navmesh := GetGameManager[].GetNavmesh()
                                # `Player` is inside the navmesh.
                                Navmesh.GetClosestTriangleToPoint[Translation]
                            then:
                                set MaybePlayer = option{Player}
                                break
                        break
                    
                    set MaybeTargetedPlayer = MaybePlayer
                    MaybePlayer?

                GetMovementTolerance<public>()<transacts> : type{t : float where t > 0.0} = Advanced.MovementTolerance

                GetIdleDuration<public>()<transacts> : type{t : float where t >= 0.0} = Advanced.IdleDuration

                GetIdleSequence<public>()<transacts> : cinematic_sequence_device = Advanced.IdleSequence
                
                GetPatrolPoints<public>()<transacts> : []vector3 = Advanced.PatrolPoints

                GetPatrolSequence<public>()<transacts> : cinematic_sequence_device = Advanced.PatrolSequence
                
                GetChasePlayerSequence<public>()<transacts> : cinematic_sequence_device = Advanced.ChasePlayerSequence

                GetChaseSpeedMultiplier<public>()<transacts> : type{t : float where t > 0.0} = Advanced.ChaseSpeedMultiplier

                GetChaseUpdateRate<public>()<transacts> : type{t : float where t >= 0.0} = Advanced.ChaseUpdateRate
                
                GetPlayersInSight<public>()<transacts> : []player = PlayersInSight
