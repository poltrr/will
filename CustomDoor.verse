using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }

CustomDoor<public> := module:
    # Types #
    
    int_positive<internal> := type{t : int where t >= 0}
    
    float_positive<internal> := type{t : float where t >= 0.0}

    degrees<internal> := type{t : float where t >= 0.0, t <= 360.0}

    door_anchor<internal> := enum:
        Left
        Right
    
    door_state<internal> := enum:
        Opened
        Closed
        Transitioning

    # Structs #

    door_type<public> := struct<concrete>:
        # Degrees to apply around the z-axis, to open/close the door.
        @editable
        DegreesToOpen<public> : float = 90.0

        # Seconds it takes to open/close the door.
        @editable
        SecondsToOpen<public> : float_positive = 0.25

        # Open-action text displayed by the door.
        @editable
        TextToOpen<public> : string = "Open"

        # Close-action text displayed by the door.
        @editable
        TextToClose<public> : string = "Close"

        # Audio played when the door opens.
        # Set `Play Location` of `audio_player_device` to `Local Player` so everyone can hear the sound.
        @editable
        AudioPlayerOpen<public> : audio_player_device = audio_player_device{}

        # Audio played when the door closes.
        # Set `Play Location` of `audio_player_device` to `Local Player` so everyone can hear the sound.
        @editable
        AudioPlayerClose<public> : audio_player_device = audio_player_device{}
    
    # Classes #
    
    door<public> := class<concrete>:
        # Attributes #
        
        # Creative prop manipulated by the door.
        @editable
        Prop<private> : creative_prop = creative_prop{}

        # Button assigned to open the door.
        @editable
        Button<private> : button_device = button_device{}

        # Type identifier for the door. The settings of the selected type will be replicated for this instance.
        # If no type is assigned this index, then default settings will be used, instead.
        @editable
        TypeIndex<private> : int_positive = 0

        # State the door is in, on start.
        # Setting `InitialState` to `Opened` doesn't open the door on start. Rather, you should set it to `Opened` when 
        #   `Prop` is opened by default.
        @editable
        InitialState<private> : door_state = door_state.Closed

        # Degrees pointing to the front of the door. 
        # 0.0°: Positive x-axis.
        # 90.0°: Positive y-axis.
        # 180.0°: Negative x-axis.
        # 270.0°: Negative y-axis.
        # This is used to calculated the side of the door the player's on when they open the door.
        @editable
        FrontFaceDegrees<private> : degrees = 0.0

        # Side the door rotates around.
        # Looking from the front, it's the side where the door hinges are.
        @editable
        Anchor<private> : door_anchor = door_anchor.Left

        # Current type.
        var Type<private> : door_type = door_type{}

        # Initial rotation of the door prop.
        var InitialRotation<private> : rotation = IdentityRotation()

        # Whether the door is opened, closed or transitioning to one.
        var CurrentState<private> : door_state = door_state.Opened

        # Minimum seconds needed to disable `Button` during the state transition.
        # `Enable()` has a delay when called in close succession to `Disable()`, therefore we only disable the button
        #   when `SecondsToOpen` is long enough.
        MinimumSecondsToOpenToDisableButton<private> : float = 0.5

        # Methods #

        # Initialize with default type.
        Init<public>() : void =
            set CurrentState = InitialState
            set InitialRotation = Prop.GetTransform().Rotation
            Button.SetInteractionText(ToMessage(Type.TextToOpen))
            
            # Calculate door's `InitialRotation` if initially opened.
            if (InitialState = door_state.Opened):
                # Inverts door rotation if the anchor is on the right.
                var RotationSign : float = 1.0
                if (Anchor = door_anchor.Right):
                    set RotationSign *= -1.0
                
                RadiansToOpen := DegreesToRadians(Type.DegreesToOpen) * RotationSign
                set InitialRotation = InitialRotation.ApplyLocalRotationZ(RadiansToOpen)
                Button.SetInteractionText(ToMessage(Type.TextToClose))
            
            # Subscribe to `Button` interaction.
            Button.InteractedWithEvent.Subscribe(OnButtonInteractedWith)

        # Initialize with assigned type.
        Init<public>(InType : door_type) : void =
            set Type = InType
            Init()
        
        # Open door if closed.
        Open<public>(Player : player)<suspends> : void =
            if (CurrentState = door_state.Closed):
                var RotationSign : float = 1.0
                
                # Invert rotation if the door is opened from the back.
                if (FortCharacter := Player.GetFortCharacter[]):
                    Translation := Prop.GetTransform().Translation
                    RadiansToFront := DegreesToRadians(FrontFaceDegrees)
                    VectorToPlayer := FortCharacter.GetTransform().Translation - Translation
                    VectorToFront := vector3{X := Cos(RadiansToFront); Y := Sin(RadiansToFront)}
                    Dot := DotProduct(VectorToFront, VectorToPlayer)
                    
                    # Invert door open rotation if opened from the back.
                    if (Dot < 0.0):
                        set RotationSign *= -1.0
                else:
                    Print("[Error] Failed to get `FortCharacter` from `Player`.", ?Color := NamedColors.Red)
                # Invert rotation if the anchor is on the right.
                if (Anchor = door_anchor.Right):
                    set RotationSign *= -1.0

                TransitionTo(
                    door_state.Opened,
                    Type.AudioPlayerOpen,
                    Player,
                    ToMessage(Type.TextToClose),
                    InitialRotation.ApplyLocalRotationZ(DegreesToRadians(-Type.DegreesToOpen * RotationSign)),
                    Type.SecondsToOpen
                )
        
        # Close door if opened.
        Close<public>(Player : player)<suspends> : void =
            if (CurrentState = door_state.Opened):
                TransitionTo(
                    door_state.Closed,
                    Type.AudioPlayerClose,
                    Player,
                    ToMessage(Type.TextToOpen),
                    InitialRotation,
                    Type.SecondsToOpen
                )
        
        # Toggle the doors state.
        # Open door if it's closed, or close it if it's opened.
        Toggle<public>(Player : player)<suspends> : void =
            case (CurrentState):
                door_state.Opened => Close(Player)
                door_state.Closed => Open(Player)
                door_state.Transitioning =>

        # Succeeds if the door is opened.
        IsOpened<public>()<transacts><decides> : void =
            CurrentState = door_state.Opened
        
        # Succeeds if the door is closed.
        IsClosed<public>()<transacts><decides> : void =
            CurrentState = door_state.Closed

        # Transition to a state.
        TransitionTo<private>(
            State : door_state,
            AudioPlayer : audio_player_device,
            Player : player,
            InteractionText : message,
            Rotation : rotation,
            SecondsToTransition : float
        )<suspends> : void =
            # Begin transition.
            set CurrentState = door_state.Transitioning
            # Play sound from instigating player.
            AudioPlayer.Play(Player)
            # Update interaction text.
            Button.SetInteractionText(InteractionText)
            # Disable interaction during transition.
            if (SecondsToTransition >= MinimumSecondsToOpenToDisableButton):
                Button.Disable()
            
            # Rotate the door.
            Translation := Prop.GetTransform().Translation
            Prop.MoveTo(Translation, Rotation, SecondsToTransition)

            # Re-enable interaction.
            if (SecondsToTransition >= MinimumSecondsToOpenToDisableButton):
                Button.Enable()
            # Update state.
            set CurrentState = State
        
        # Convert `Text` from string to message.
        ToMessage<private><localizes>(Text : string) : message = "{Text}"

        # Callbacks #

        # Toggle door state when interacted with.
        OnButtonInteractedWith<private>(InAgent : agent) : void =
            if (Player := player[InAgent]):
                spawn{Toggle(Player)}
        
        # Getters #

        GetProp<public>()<transacts> : creative_prop = Prop

        GetButton<public>()<transacts> : button_device = Button

        GetTypeIndex<public>()<transacts> : int_positive = TypeIndex

        GetType<public>()<transacts> : door_type = Type

        GetTransform<public>()<transacts> : transform = Prop.GetTransform()

    door_manager<public> := class(creative_device):
        # Attributes #

        # Door types available.
        @editable
        Types<private> : []door_type = array{}
        # Door instances.
        @editable
        Doors<private> : []door = array{}
        
        # Methods #

        OnBegin<override>()<suspends> : void =
            for (Index -> Door : Doors):
                # Initialize `Door`.
                if (Type := Types[Door.GetTypeIndex()]):
                    Door.Init(Type)
                else:
                    Door.Init()

        # Getters #

        GetTypes<public>()<transacts> : []door_type = Types

        GetDoors<public>()<transacts> : []door = Doors

        GetType<public>(Index : int)<transacts><decides> : door_type = Types[Index]
        
        GetDoor<public>(Index : int)<transacts><decides> : door = Doors[Index]
