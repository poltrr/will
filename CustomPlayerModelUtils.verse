using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { CustomPlayerModel }

CustomPlayerModelUtils<public> := module:
    button_custom_model_assigner<public> := class(creative_device):
        # Attributes #
        
        # Button that assigns model to players that interact with it.
        @editable
        Button<private> : button_device = button_device{}

        # Custom player model devices that players can be assigned to.
        @editable
        CustomPlayerModelDevices<private> : []custom_player_model = array{}

        # Methods #

        OnBegin<override>()<suspends> : void =
            Button.InteractedWithEvent.Subscribe(OnButtonInteractedWith)

        GetAvailableCustomPlayerModelDevice<private>()<transacts><decides> : custom_player_model =
            for (Device : CustomPlayerModelDevices):
                if (AssignedPlayer := Device.GetPlayer[]) {}
                else:
                    return Device
            false?

        OnButtonInteractedWith<private>(InAgent : agent) : void =
            if (Player := player[InAgent]; CustomPlayerModelDevice := GetAvailableCustomPlayerModelDevice[]):
               CustomPlayerModelDevice.GiveControlTo(Player)
