using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { FiniteStateMachine }

CustomPlayerModel<public> := module:
    # Enums #

    # States that can be overriden by the custom model.
    state<internal> := enum:
        Idle
        Walk
        Crouch
        Sneak
        Jump
        Fall
    
    # Direction of the movement.
    direction<internal> := enum:
        Front
        Back
        Left
        Right
    
    # Cast `state` to string.
    ToString<internal>(State : state) : string =
        case (State):
            state.Idle => "Idle"
            state.Walk => "Walk"
            state.Crouch => "Crouch"
            state.Sneak => "Sneak"
            state.Jump => "Jump"
            state.Fall => "Fall"
    
    # Structs #

    struct_title<internal> := struct<concrete>{}
    
    # Classes #

    fsm<internal> := class<final>(finite_state_machine):
        # Attributes #
        
        # Custom player model controlled by the state machine.
        var MaybeCustomPlayerModel<private> : ?custom_player_model = false

        StateIdle<private> : state_idle = state_idle{}

        StateWalk<private> : state_walk = state_walk{}

        StateCrouch<private> : state_crouch = state_crouch{}
        
        StateSneak<private> : state_sneak = state_sneak{}

        StateJump<private> : state_jump = state_jump{}

        StateFall<private> : state_fall = state_fall{}
    
        # Methods #
    
        # Start the state machine, and injects the player reference.
        # Wrapper for `Start<protected>`.
        Start<public>(InCustomPlayerModel : custom_player_model) : void =
            StateIdle.Initialize(Self, state.Idle)
            StateWalk.Initialize(Self, state.Walk)
            StateCrouch.Initialize(Self, state.Crouch)
            StateSneak.Initialize(Self, state.Sneak)
            StateJump.Initialize(Self, state.Jump)
            StateFall.Initialize(Self, state.Fall)
            
            set MaybeCustomPlayerModel = option{InCustomPlayerModel}
            set MaybeCurrentState = option{StateIdle}
            Start()
        
        GetCustomPlayerModel<public>()<transacts><decides> : custom_player_model = MaybeCustomPlayerModel?

        GetStateIdle<public>()<transacts> : state_idle = StateIdle

        GetStateWalk<public>()<transacts> : state_walk = StateWalk

        GetStateCrouch<public>()<transacts> : state_crouch = StateCrouch
        
        GetStateSneak<public>()<transacts> : state_sneak = StateSneak
        
        GetStateJump<public>()<transacts> : state_jump = StateJump

        GetStateFall<public>()<transacts> : state_fall = StateFall
    
    base_state<internal> := class<abstract>(base_state_interface):
        # Attributes #
        
        # State machine that owns this state.
        var MaybeOwner<protected> : ?fsm = false

        # State type described by this state.
        var MaybeState<protected> : ?state = false
    
        # Methods #

        # Initialize state by injecting dependencies.
        Initialize<public>(Owner : fsm, State : state) : void =
            set MaybeOwner = option{Owner}
            set MaybeState = option{State}

        # Play the state animation sequence.
        # Remember to call `(super:).Enter()` if you override this further.
        Enter<override>() : void =
            if (Owner := MaybeOwner?; State := MaybeState?; InCustomPlayerModel := Owner.GetCustomPlayerModel[]):
                Print("Entered {ToString(State)}.")
                InCustomPlayerModel.PlaySequenceForState(State)
        
        # Helper `Update` method with commonly used parameters.
        # Override this instead of `Update<public>`.
        Update<protected>(
            Owner : fsm,
            InCustomPlayerModel : custom_player_model,
            FortCharacter : fort_character
        )<suspends> : ?base_state

        # Wrapper for `Update<public>`.
        # Call helper method `Update<protected>` once both `Owner` and `InCustomPlayerModel` have been set.
        # Do not override further.
        Update<override>()<suspends> : ? base_state =
            if:
                Owner := MaybeOwner?
                InCustomPlayerModel := Owner.GetCustomPlayerModel[]
                Player := InCustomPlayerModel.GetPlayer[]
                FortCharacter := Player.GetFortCharacter[]
            then:
                Update(Owner, InCustomPlayerModel, FortCharacter)
            else:
                false

        # Stop the state animation sequence.
        # Remember to call `(super:).Exit()` if you override this further.
        Exit<override>() : void =
            if (Owner := MaybeOwner?; State := MaybeState?; InCustomPlayerModel := Owner.GetCustomPlayerModel[]):
                InCustomPlayerModel.StopSequenceForState(State)

        GetOwner<public>()<transacts><decides> : fsm = MaybeOwner?

        GetState<public>()<transacts><decides> : state = MaybeState?
    
    state_idle<internal> := class<concrete><final>(base_state):
        # Methods #

        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            if(InCustomPlayerModel.GetIsMoving()?):
                return option{Owner.GetStateWalk()}
            else if (InCustomPlayerModel.GetIsCrouching()?):
                return option{Owner.GetStateCrouch()}
            else if (FortCharacter.IsFalling[]):
                return option{Owner.GetStateJump()}
            
            false
    
    state_move<internal> := class<concrete>(base_state):
        # Attributes #

        var MaybePreviousDirection<private> : ?direction = false

        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            Direction := InCustomPlayerModel.GetCurrentDirection()

            # Re-enter state to play new animation, according to the current direction.
            if (PreviousDirection := MaybePreviousDirection?; Direction <> PreviousDirection):
                return option{Self}

            set MaybePreviousDirection = option{Direction}
            
            false
        
        Exit<override>() : void =
            if:
                Owner := MaybeOwner?
                State := MaybeState?
                InCustomPlayerModel := Owner.GetCustomPlayerModel[]
                PreviousDirection := MaybePreviousDirection?
            then:
                InCustomPlayerModel.StopSequenceForState(State, ?Direction := PreviousDirection)
            set MaybePreviousDirection = false
    
    state_walk<internal> := class<concrete><final>(state_move):
        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            # Run superclass' `Update`, and update to any returning state.
            Result := (super:)Update(Owner, InCustomPlayerModel, FortCharacter)
            if (Result?):
                return Result
            
            if(not InCustomPlayerModel.GetIsMoving()?):
                return option{Owner.GetStateIdle()}
            else if (InCustomPlayerModel.GetIsCrouching()?):
                return option{Owner.GetStateSneak()}
            else if (FortCharacter.IsFalling[]):
                return option{Owner.GetStateJump()}
            
            false
    
    state_crouch<internal> := class<concrete><final>(base_state):
        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            if(InCustomPlayerModel.GetIsMoving()?):
                return option{Owner.GetStateSneak()}
            else if (not InCustomPlayerModel.GetIsCrouching()?):
                return option{Owner.GetStateIdle()}
            else if (FortCharacter.IsFalling[]):
                return option{Owner.GetStateJump()}
            
            false
    
    state_sneak<internal> := class<concrete><final>(state_move):
        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            # Run superclass' `Update`, and update to any returning state.
            Result := (super:)Update(Owner, InCustomPlayerModel, FortCharacter)
            if (Result?):
                return Result
            
            if(not InCustomPlayerModel.GetIsMoving()?):
                return option{Owner.GetStateCrouch()}
            else if (not InCustomPlayerModel.GetIsCrouching()?):
                return option{Owner.GetStateWalk()}
            else if (FortCharacter.IsFalling[]):
                return option{Owner.GetStateJump()}
            
            false
    
    state_jump<internal> := class<concrete><final>(base_state):
        # Attributes #

        var MaybePreviousHeight<private> : ?float = false
        
        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            Height := FortCharacter.GetTransform().Translation.Z

            # Check if the player's movement is negative in the Z-axis.
            if:
                PreviousHeight := MaybePreviousHeight?
                Displacement := Height - PreviousHeight
                Displacement < 0.0
            then:
                return option{Owner.GetStateFall()}
            else if (not FortCharacter.IsFalling[]):
                return option{Owner.GetStateIdle()}
            
            set MaybePreviousHeight = option{Height}
            
            false
        
        Exit<override>() : void =
            (super:)Exit()
            set MaybePreviousHeight = false
    
    state_fall<internal> := class<concrete><final>(base_state):
        # Methods #
        
        Update<override>(Owner : fsm, InCustomPlayerModel : custom_player_model, FortCharacter : fort_character)<suspends> : ?base_state =
            if (not FortCharacter.IsFalling[]):
                if (InCustomPlayerModel.GetIsMoving()?):
                    return option{Owner.GetStateWalk()}
                else:
                    return option{Owner.GetStateIdle()}
            
            false
    
    custom_player_model<public> := class(creative_device):
        # Attributes #
        
        # Custom model creative prop.
        @editable
        Model<private> : creative_prop = creative_prop{}
        
        # Empty struct to display a title in the Details inspector tab.
        @editable CinematicSequencers<private> : struct_title = struct_title{}
        
        # Cinematic sequencer for idle animation.
        @editable
        Idle<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for walk animation.
        @editable
        Walk<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for walk animation (backwards).
        @editable
        WalkBackwards<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for walk animation (sideways - left).
        @editable
        WalkLeft<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for walk animation (sideways - right).
        @editable
        WalkRight<private> : cinematic_sequence_device = cinematic_sequence_device{}
        
        # Cinematic sequencer for crouch animation.
        @editable
        Crouch<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for sneak animation.
        @editable
        Sneak<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for sneak animation (backwards).
        @editable
        SneakBackwards<private> : cinematic_sequence_device = cinematic_sequence_device{}
        
        # Cinematic sequencer for sneak animation (sideways - left).
        @editable
        SneakLeft<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for sneak animation (sideways - right).
        @editable
        SneakRight<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for jump animation.
        @editable
        Jump<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Cinematic sequencer for fall animation.
        @editable
        Fall<private> : cinematic_sequence_device = cinematic_sequence_device{}

        # Empty struct to display a title in the Details inspector tab.
        @editable Advanced<private> : struct_title = struct_title{}

        # Seconds between each update (translation).
        # x = 0.0: One server frame.
        # x > 0.0: For x seconds.
        # x = Inf: Infinite, will not update.
        @editable
        var UpdateRate<private> : type{t : float where t >= 0.0} = 0.0

        # Frames of no player movement needed to set `IsMoving` to false.
        # Note: Due to UEFN limitations, the server might detect no movement from player's with low latency; even if
        #       they are moving locally.
        #       To avoid a negative user experience, a higher tolerance value can be provided.
        #       Still, a high tolerance value might also bring a negative user experience, as the higher the tolerance,
        #       the more out of sync the custom model will be from the player.
        #       A value of 2 is recommended by me :)
        @editable
        MovementStopTolerance : type{t : int where t >= 0} = 2

        # Seconds that the custom model's movement will be offset from the player's.
        # The smaller the value, the closer it's translation will be to the player at any moment.
        # Note: A small number (< 0.1) may cause the custom model's movement to be choppy.
        @editable
        MovementOffsetSeconds : type{t : float where t >= 0.0} = 0.1

        # Offset apply to the custom model's translation, from the camera origin.
        # A higher value will move the custom model further from the camera.
        # A slower value will bring the custom model closer to the camera.
        @editable
        ForwardOffsetMeters : float = 0.5

        # Whether `ForwardOffsetMeters` should be ignored when the player is idle or crouching.
        @editable
        IgnoreForwardOffsetWhenNotMoving : logic = true

        # State machine that handles the custom model's behavior.
        StateMachine<private> : fsm = fsm{}

        # Player controlling the custom model.
        var MaybePlayer<private> : ?player = false

        # Direction of the current movement.
        var CurrentDirection : direction = direction.Front

        # Whether the controlling player is moving.
        var IsMoving<private> : logic = false

        # Whether the controlling player is crouching.
        var IsCrouching<private> : logic = false

        # Centimeters the player has to translate to consider they're moving.
        MovementAbsoluteTolerance : float = 0.1
        
        # Offset applied to the Z-axis of the `Model` translation by default.
        ModelTranslationZOffset<private> : float = -80.0

        # Offset applied to the Z-axis of the `Model` translation when crouched.
        ModelTranslationZOffsetCrouch<private> : float = -56.0

        # Methods #
        
        # Assign control of the custom model to `Player`.
        # Any previous player will lose control.
        GiveControlTo<public>(Player : player) : void =
            Stop() # Stop previous control.
            AssignedPlayerSuccessfully := AssignPlayer(Player)
            if (AssignedPlayerSuccessfully?):
                StateMachine.Start(Self)
            else { Print("[Error] Failed to assign `Player` to `CustomPlayerModel`.", ?Color := NamedColors.Red) }
        
        # Stop the control of the custom model.
        Stop<public>() : void =
            StateMachine.Stop()
            if (Player := MaybePlayer?):
                set MaybePlayer = false
                # Make previous player visible.
                if (FortCharacter := Player.GetFortCharacter[]):
                    FortCharacter.Show()

        # Play the animation sequence for `State`, if overridden.
        PlaySequenceForState<internal>(State : state) : void =
            case(State):
                state.Idle => Idle.Play()
                state.Walk =>
                    case(CurrentDirection):
                        direction.Front => Walk.Play()
                        direction.Back => WalkBackwards.Play()
                        direction.Left => WalkLeft.Play()
                        direction.Right => WalkRight.Play()
                state.Crouch => Crouch.Play()
                state.Sneak =>
                    case(CurrentDirection):
                        direction.Front => Sneak.Play()
                        direction.Back => SneakBackwards.Play()
                        direction.Left => SneakLeft.Play()
                        direction.Right => SneakRight.Play()
                state.Jump => Jump.Play()
                state.Fall => Fall.Play()
        
        # Stop the animation sequence for `State`.
        StopSequenceForState<internal>(State : state, ?Direction : direction = direction.Front) : void =
            case(State):
                state.Idle => Idle.Stop()
                state.Walk =>
                    case(Direction):
                        direction.Front => Walk.Stop()
                        direction.Back => WalkBackwards.Stop()
                        direction.Left => WalkLeft.Stop()
                        direction.Right => WalkRight.Stop()
                state.Crouch => Crouch.Stop()
                state.Sneak =>
                    case(Direction):
                        direction.Front => Sneak.Stop()
                        direction.Back => SneakBackwards.Stop()
                        direction.Left => SneakLeft.Stop()
                        direction.Right => SneakRight.Stop()
                state.Jump => Jump.Stop()
                state.Fall => Fall.Stop()
        
        # Assigns a new player as the custom model's control.
        # Returns true if succeeded, else if failed.
        # Note: Can't be a failable <decides> method as it calls a spawn{}.
        AssignPlayer<private>(Player : player) : logic =
            if (FortCharacter := Player.GetFortCharacter[]):
                set MaybePlayer = option{Player}
                FortCharacter.Hide()
                spawn{AsyncUpdate(Player, FortCharacter)}
                
                true
            else:
                false
        
        AsyncUpdate<private>(Player : player, FortCharacter: fort_character)<suspends> : void =
            race:
                AsyncUpdateIsMovingAndIsCrouching(Player, FortCharacter)
                AsyncUpdateModelTransform(FortCharacter)
        
        # Moves `Model` prop to the player's translation.
        AsyncUpdateModelTransform<private>(FortCharacter : fort_character)<suspends> : void =
            loop:
                PlayerTranslation := FortCharacter.GetTransform().Translation
                PlayerRotation := FortCharacter.GetTransform().Rotation

                # Get offset from camera.
                ForwardOffset := 
                    if:
                        IgnoreForwardOffsetWhenNotMoving?
                        State := StateMachine.GetCurrentState[]
                        state_idle[State] or state_crouch[State]
                    then:
                        vector3{}
                    else:
                        PlayerRotation.GetLocalForward() * (ForwardOffsetMeters * 100)
                
                # Get offset on Z-axis.
                OffsetZ := if(State := StateMachine.GetCurrentState[]; state_crouch[State] or state_sneak[State])
                    then ModelTranslationZOffsetCrouch
                    else ModelTranslationZOffset
                
                Target := vector3:
                    X := PlayerTranslation.X + ForwardOffset.X
                    Y := PlayerTranslation.Y + ForwardOffset.Y
                    Z := PlayerTranslation.Z + ForwardOffset.Z + OffsetZ
                
                # Begin movement.
                Model.MoveTo(Target, PlayerRotation, MovementOffsetSeconds)
        
        # Subscribe to `CrouchedEvent()`.
        # Unsubcribe when the controlling player changes.
        AsyncUpdateIsMovingAndIsCrouching<private>(Player : player, FortCharacter : fort_character)<suspends> : void =
            var MaybePreviousTranslation2 : ?vector2 = false
            var NoMovementFrames : int = 0
            
            Cancelable := FortCharacter.CrouchedEvent().Subscribe(OnPlayerCrouched)
            
            loop:
                if (CurrentPlayer := MaybePlayer?; CurrentPlayer = Player):
                    Translation2 := vector2:
                        X := FortCharacter.GetTransform().Translation.X
                        Y := FortCharacter.GetTransform().Translation.Y
                    
                    if (PreviousTranslation2 := MaybePreviousTranslation2?):
                        Displacement2 := Translation2 - PreviousTranslation2
                        
                        # Update `IsMoving`.
                        if (Displacement2.Length() > MovementAbsoluteTolerance):
                            set IsMoving = true

                            Rotation := FortCharacter.GetTransform().Rotation
                            UpdateDirection(Rotation, Displacement2)
                        else:
                            if (NoMovementFrames >= MovementStopTolerance):
                                set IsMoving = false
                                set NoMovementFrames = 0
                            else:
                                set NoMovementFrames += 1
                    
                    set MaybePreviousTranslation2 = option{Translation2}
                    
                    Sleep(UpdateRate)
                else:
                    break
            
            # Stop listening to previous player's `CrouchedEvent()`.
            Cancelable.Cancel()
        
        # Update's `CurrentDirection` based on the player's movement.
        UpdateDirection<private>(Rotation : rotation, Displacement2 : vector2) : void =
            LocalForwardXY := vector3{X := Rotation.GetLocalForward().X; Y := Rotation.GetLocalForward().Y; Z := 0.0}
            DisplacementXY := vector3{X := Displacement2.X; Y := Displacement2.Y; Z := 0.0}

            Angle := MakeShortestRotationBetween(LocalForwardXY, DisplacementXY ).GetAngle()
            
            # Update value.
            if (Angle <= 0.786):
                set CurrentDirection = direction.Front
            else if (Angle >= 2.355):
                set CurrentDirection = direction.Back
            else:
                # Determines if the movement direction is left or right to the player's rotation.
                Dot := DotProduct(Rotation.GetLocalRight(), DisplacementXY)
                if (Dot < 0.0):
                    set CurrentDirection = direction.Left
                else:
                    set CurrentDirection = direction.Right
        
        # `(:fort_character).CrouchedEvent()` callback.
        OnPlayerCrouched<private>(FortCharacter : fort_character, Crouching : logic) : void =
            set IsCrouching = Crouching

        GetPlayer<public>()<transacts><decides> : player = MaybePlayer?

        GetIsMoving<public>()<transacts> : logic = IsMoving

        GetIsCrouching<public>()<transacts> : logic = IsCrouching

        GetUpdateRate<public>()<transacts> : float = UpdateRate

        GetCurrentDirection<internal>()<transacts> : direction = CurrentDirection

        GetModelTranslationZOffset<public>()<transacts> : float = ModelTranslationZOffset

        GetModelTranslationZOffsetCrouch<public>()<transacts> : float = ModelTranslationZOffsetCrouch

        SetUpdateRate<public>(InUpdateRate : type{t : float where t >= 0.0}) : void =
            set UpdateRate = InUpdateRate
