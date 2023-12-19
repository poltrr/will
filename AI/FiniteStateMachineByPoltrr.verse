using { /Verse.org/Simulation }

FiniteStateMachineByPoltrr<public> := module:
    state<public> := class<abstract>:
        # Methods #
        
        # Called before the first update.
        Enter<public>() : void = {}

        # Called consecutively while the state is active.
        Update<public>()<suspends> : ?state = false
        
        # Called after the last update.
        Exit<public>() : void = {}
    
    finite_state_machine<public> := class<abstract>:
        # Attributes #

        # Current state.
        var MaybeCurrentState<private> : ?state = false

        # Whether it is active.
        var Active<private> : logic = false
        
        # Methods #

        # Start finite state machine with an `InitialState`.
        Start<protected>(InitialState : state) : void =
            if (not Active?):
                set Active = true
                set MaybeCurrentState = option{InitialState}
                spawn{AsyncStart()}
        
        # Stop finite state machine.
        Stop<public>() : void =
            set Active = false
        
        # Start finite state machine's lifecycle.
        AsyncStart<private>()<suspends> : void =
            loop:
                if (CurrentState := MaybeCurrentState?):
                    AsyncUpdate(CurrentState)
                else:
                    break
        
        # Enter, update and exit `MaybeCurrentState` throughout its lifecycle.
        AsyncUpdate<private>(State : state)<suspends> : void =
            # Exit `State` at the end of its lifecycle.
            defer{State.Exit()}
            # Enter `State`.
            State.Enter()
            # Update `State` until a state transition occurs.
            loop:
                MaybeNextState := State.Update()
                # Stop finite state machine.
                if (not Active?):
                    set MaybeCurrentState = false
                    break
                # Transition to `NextState`.
                if (NextState := MaybeNextState?):
                    set MaybeCurrentState = option{NextState}
                    break
                Sleep(0.0)
        
        # Succeeds if the finite state machine is active.
        IsActive<public>()<transacts><decides> : void = Active?

        GetCurrentState<public>()<transacts><decides> : state = MaybeCurrentState?
