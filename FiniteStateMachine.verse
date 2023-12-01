using { /Verse.org/Simulation }

FiniteStateMachine<public> := module:
    # Interface for a finite state machine's state.
    # Create an abstract class implementation to fit your needs.
    base_state_interface<public> := interface():
        # Called when the state becomes active, and before the first Update call.
        # Override with any enter behavior.
        Enter<public>() : void
        # Called (almost) every frame while the state is active.
        # Override with the state's behavior.
        Update<public>()<suspends> : ?base_state_interface
        # Called before the state becomes inactive, and after the last Update call.
        # Override with any exit behavior.
        Exit<public>() : void
    
    # Abstract implementation of a finite state machine.
    # Create a subclass and override as needed to fit your needs.
    finite_state_machine<public> := class<abstract>():
        # Attributes #
        
        # The current state.
        # Set the starting state from your subclass.
        var MaybeCurrentState<protected> : ?base_state_interface = false
        # Describes if the state machine is currently active.
        var IsActive<protected> : logic = false

        # Methods #

        # Start the execution of the state machine, and enter the starting state.
        # Create a public Start method from your subclass to wrap this.
        Start<protected>() : void =
            if (not IsActive?; CurrentState := MaybeCurrentState?):
                set IsActive = true
                # Enter the starting state.
                CurrentState.Enter()
                # Begins executing the update method on the current state.
                spawn{Update()}
        
        # Update the state machine each frame.
        Update<private>()<suspends> : void =
            loop:
                # Stop running the state machine when it's deactivated.
                if (not IsActive?) then break
                spawn{UpdateCurrentState()}
                Sleep(0.0)
        
        # Stop the execution of the state machine.
        Stop<public>() : void =
            set IsActive = false
        
        # Update the current state, and handle its transitions.
        # Execute the update method on the current state, and transition to a new state if the conditions are met.
        UpdateCurrentState<private>()<suspends> : void =
            if (CurrentState := MaybeCurrentState?):
                # Updates the current state.
                MaybeNewState : ?base_state_interface = CurrentState.Update()
                if (NewState := MaybeNewState?):
                    TransitionTo(NewState)
        
        # Transition from the current state, to a new state, and exit the current state.
        TransitionTo<private>(NewState : base_state_interface) : void =
            if (CurrentState := MaybeCurrentState?):
                CurrentState.Exit()
                set MaybeCurrentState = option{NewState}
                NewState.Enter()
        
        GetCurrentState<public>()<transacts><decides> : base_state_interface = MaybeCurrentState?
