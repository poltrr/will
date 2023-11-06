using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Verse.org/Colors }
using { /Verse.org/Simulation }

FlashlightController<public> := module:
    flashlight_controller<public> := class(creative_device):
        # Attributes #

        # Customizable light device, to be used as flashlight.
        @editable
        Flashlight<private> : customizable_light_device = customizable_light_device{}

        # Seconds between each update (translation).
        # x <= 0: One server frame.
        # x > 0: For x seconds.
        # x = Inf: Infinite, will not update.
        @editable
        var UpdateRate<private> : float = 0.0

        # Wheter the flashlight is granted, to all players, automatically.
        @editable
        GrantOnStart<private> : logic = false

        # Map players with flashlight to whether it's turned on.
        var PlayerHasFlashlightOn<private> : [fort_character]logic = map{}
        
        # Methods #

        OnBegin<override>()<suspends> : void =
            # Add all players to `PlayerHasFlashlightOn`, if `GrantOnStart`.
            if (GrantOnStart?):
                Players := GetPlayspace().GetPlayers()
                for (Player : Players; FortCharacter := Player.GetFortCharacter[]):
                    if (set PlayerHasFlashlightOn[FortCharacter] = true) {}
                    else { Print("[Error] Failed to map `Player` in `PlayerHasFlashlightOn`.", ?Color := NamedColors.Red) }
            
            # Began async method.
            block:
                Async()
        
        Async<private>()<suspends> : void =
            loop:
                for (FortCharacter -> IsFlashlightOn : PlayerHasFlashlightOn):
                    # Teleport and rotate the flashlight to the player, and turn on.
                    if (IsFlashlightOn?):
                        # Attach flashlight's to player's view.
                        Transform := FortCharacter.GetTransform()
                        Translation := Transform.Translation
                        ViewRotation := FortCharacter.GetViewRotation()
                        if (Flashlight.TeleportTo[Translation, Flashlight.GetTransform().Rotation]):
                            Flashlight.MoveTo(Translation, ViewRotation, 0.2)
                        else { Print("[Error] Failed `TeleportTo[]` on `Flashlight`.", ?Color := NamedColors.Red) }
                        # Assure flashlight is on.
                        Flashlight.TurnOn()
                    # Turn flashlight off.
                    else:
                        Flashlight.TurnOff()
                # Loop delay.
                Sleep(UpdateRate)
        
        # Succeeds if `Player` has a flashlight granted.
        HasFlashlight<public>(Player : player)<transacts><decides> : void =
            FortCharacter := Player.GetFortCharacter[]
            PlayerHasFlashlightOn[FortCharacter]
        
        # Succeeds if `Player` has their flashlight turned off.
        # Fails if `Player` doesn't have a flashlight granted, or it's turned off.
        HasFlashlightTurnedOn<public>(Player : player)<transacts><decides> : void =
            FortCharacter := Player.GetFortCharacter[]
            PlayerHasFlashlightOn[FortCharacter]?
        
        # Grant a flashlight to `Player`.
        # `TurnedOn` determines whether it is granted on, or off.
        GrantTo<public>(Player : player, ?TurnedOn : logic = true) : void =
            if (FortCharacter := Player.GetFortCharacter[]):
                # Don't grant if `Player` has flashlight already.
                if (PlayerHasFlashlightOn[FortCharacter]):
                    Print("[Error] `Player` already has a flashlight.", ?Color := NamedColors.Red)
                # Grant flashlight.
                else if (set PlayerHasFlashlightOn[FortCharacter] = TurnedOn) {}
                else { Print("[Error] Failed to map `FortCharacter` in `PlayerHasFlashlightOn`.", ?Color := NamedColors.Red) }
            else:
                Print("[Error] Failed to get `FortCharacter` from `Player`.", ?Color := NamedColors.Red)
        
        # Grant a flashlight to all players in the session.
        # `TurnedOn` determines whether they are granted on, or off.
        GrantToAll<public>(?TurnedOn : logic = true) : void =
            Players := GetPlayspace().GetPlayers()
            for (Player : Players):
                GrantTo(Player, ?TurnedOn := true)
        
        # Turn on `Player`'s flashlight.
        TurnOn<public>(Player : player) : void =
            if:
                FortCharacter := Player.GetFortCharacter[]
                PlayerHasFlashlightOn[FortCharacter]
                set PlayerHasFlashlightOn[FortCharacter] = true
            else { Print("[Error] Failed to turn flashlight on for `Player`.", ?Color := NamedColors.Red) }
        
        # Turn off `Player`'s flashlight.
        TurnOff<public>(Player : player) : void =
            if:
                FortCharacter := Player.GetFortCharacter[]
                PlayerHasFlashlightOn[FortCharacter]
                set PlayerHasFlashlightOn[FortCharacter] = false
            else { Print("[Error] Failed to turn flashlight off for `Player`.", ?Color := NamedColors.Red) }
        
        # Turn on flashlight for all player's with flashlights.
        TurnOnAll<public>() : void =
            for (FortCharacter -> TurnedOn : PlayerHasFlashlightOn):
                if (set PlayerHasFlashlightOn[FortCharacter] = true) {}
                else { Print("[Error] Failed to turn flashlight on for `FortCharacter`.", ?Color := NamedColors.Red) }
        
        # Turn off flashlight for all player's with flashlights.
        TurnOffAll<public>() : void =
            for (FortCharacter -> TurnedOn : PlayerHasFlashlightOn):
                if (set PlayerHasFlashlightOn[FortCharacter] = false) {}
                else { Print("[Error] Failed to turn flashlight off for `FortCharacter`.", ?Color := NamedColors.Red) }
        
        # Return all players with flashlights.
        GetPlayersWithFlashlights<public>() : []player =
            for (FortCharacter -> TurnedOn : PlayerHasFlashlightOn; Player := player[FortCharacter.GetAgent[]]):
                Player
        
        # Getters #

        GetUpdateRate<public>() : float = UpdateRate
        
        # Setters #

        SetUpdateRate<public>(NewUpdateRate: float) : void =
            set UpdateRate = NewUpdateRate
