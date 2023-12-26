using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Verse }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { NavigationMeshSystemByPoltrr }

tag_game_manager := class(tag) {}

# Returns an instance of the Game Manager.
GetGameManager()<transacts><decides> : game_manager = game_manager[GetCreativeObjectsWithTag(tag_game_manager{})[0]]

game_manager := class(creative_device):

    # Unnamed agent device.
    @editable
    UnnamedAgent : AIAgents.Unnamed.Agent.unnamed = AIAgents.Unnamed.Agent.unnamed{}

    # Current navigation mesh.
    var Navmesh<private> : navmesh = navmesh{Vertices := array{}; Triangles := array{}}

    OnBegin<override>()<suspends> : void =
        # Prints an error if the device isn't tagged with tag_game_manager.
        TagView := GetTags()
        if (not TagView.Has[tag_game_manager{}]):
            Print("[Error] game_manager: Not all tags assigned.", ?Color := NamedColors.Red)
    
        CreateNavmesh()
        StartUnnamedAgent()

    CreateNavmesh<private>() : void =
        PrevVertices : []vector3 = array:
            vector3{X := -16.809429168701172; Y := -15.973161697387695; Z := 0.0}
            vector3{X := -3.8094286918640137; Y := -15.973161697387695; Z := 0.0}
            vector3{X := -16.831924438476562; Y := -4.247427463531494; Z := 0.0}
            vector3{X := -3.8094286918640137; Y := -4.247427463531494; Z := 0.0}
            vector3{X := -16.831924438476562; Y := -6.922337532043457; Z := 0.0}
            vector3{X := -16.831924438476562; Y := -9.247426986694336; Z := 0.0}
            vector3{X := -32.96974182128906; Y := -6.922337532043457; Z := 0.0}
            vector3{X := -32.96974182128906; Y := -9.247426986694336; Z := 0.0}
            vector3{X := -32.96974182128906; Y := -10.832242012023926; Z := 0.0}
            vector3{X := -17.969741821289062; Y := -10.832242012023926; Z := 0.0}
            vector3{X := -17.969741821289062; Y := -9.247426986694336; Z := 0.0}
            vector3{X := -17.969741821289062; Y := -6.922337532043457; Z := 0.0}
            vector3{X := -17.969741821289062; Y := -4.6060709953308105; Z := 0.0}
            vector3{X := -32.96974182128906; Y := -4.6060709953308105; Z := 0.0}
            vector3{X := -32.96974182128906; Y := 8.393928527832031; Z := 0.0}
            vector3{X := -26.685287475585938; Y := 8.393928527832031; Z := 0.0}
            vector3{X := -26.685287475585938; Y := -4.6060709953308105; Z := 0.0}
            vector3{X := -26.685287475585938; Y := -1.3216171264648438; Z := 0.0}
            vector3{X := -26.685287475585938; Y := 0.7031126022338867; Z := 0.0}
            vector3{X := -16.051013946533203; Y := 0.7031126022338867; Z := 0.0}
            vector3{X := -16.051013946533203; Y := -1.3216171264648438; Z := 0.0}
            vector3{X := -4.116379737854004; Y := -1.3216171264648438; Z := 0.0}
            vector3{X := -4.766560077667236; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -16.051013946533203; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -9.051013946533203; Y := -1.3216171264648438; Z := 0.0}
            vector3{X := -9.051013946533203; Y := -4.321617126464844; Z := 0.0}
            vector3{X := -7.051014423370361; Y := -4.321617126464844; Z := 0.0}
            vector3{X := -7.051014423370361; Y := -1.3216171264648438; Z := 0.0}
            vector3{X := -7.051014423370361; Y := -2.6873440742492676; Z := 0.0}
            vector3{X := -4.11638069152832; Y := -2.6873440742492676; Z := 0.0}
            vector3{X := -7.116379737854004; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -4.725923538208008; Y := 9.060014724731445; Z := 0.0}
            vector3{X := -7.132286071777344; Y := 9.060014724731445; Z := 0.0}
            vector3{X := -4.132286548614502; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -15.132286071777344; Y := 9.060014724731445; Z := 0.0}
            vector3{X := -15.132286071777344; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -13.132286071777344; Y := 1.6783828735351562; Z := 0.0}
            vector3{X := -13.132286071777344; Y := 5.434564590454102; Z := 0.0}
            vector3{X := -7.132286071777344; Y := 5.434564590454102; Z := 0.0}
            vector3{X := -16.725923538208008; Y := 9.060016632080078; Z := 0.0}
            vector3{X := 5.482602119445801; Y := 9.060014724731445; Z := 0.0}
            vector3{X := 4.466695785522461; Y := 18.897470474243164; Z := 0.0}
            vector3{X := -16.725923538208008; Y := 18.897470474243164; Z := 0.0}
            vector3{X := 17.669876098632812; Y := 9.060014724731445; Z := 0.0}
            vector3{X := 17.669876098632812; Y := 16.85683250427246; Z := 0.0}
            vector3{X := 4.669878005981445; Y := 16.85683250427246; Z := 0.0}
            vector3{X := 10.466693878173828; Y := 16.85683250427246; Z := 0.0}
            vector3{X := 10.466693878173828; Y := 18.856834411621094; Z := 0.0}
            vector3{X := 17.669876098632812; Y := 18.856834411621094; Z := 0.0}
            vector3{X := 17.669876098632812; Y := 5.484023094177246; Z := 0.0}
            vector3{X := 5.873056411743164; Y := 5.484023094177246; Z := 0.0}
            vector3{X := 5.873056411743164; Y := 9.060014724731445; Z := 0.0}
            vector3{X := -2.5333032608032227; Y := 9.060014724731445; Z := 0.0}
            vector3{X := -2.5333032608032227; Y := -8.664168357849121; Z := 0.0}
            vector3{X := 5.466696739196777; Y := -8.664168357849121; Z := 0.0}
            vector3{X := 5.48233699798584; Y := 5.484023094177246; Z := 0.0}
            vector3{X := 5.466696739196777; Y := -2.6641688346862793; Z := 0.0}
            vector3{X := 5.466696739196777; Y := 3.335829734802246; Z := 0.0}
            vector3{X := 17.46669578552246; Y := 3.335829734802246; Z := 0.0}
            vector3{X := 17.46669578552246; Y := -2.6641697883605957; Z := 0.0}
            vector3{X := 16.839195251464844; Y := 3.335829734802246; Z := 0.0}
            vector3{X := 7.797626495361328; Y := 3.335829734802246; Z := 0.0}
            vector3{X := 16.839195251464844; Y := 5.489487648010254; Z := 0.0}
            vector3{X := 7.839195251464844; Y := 5.489487648010254; Z := 0.0}
            vector3{X := 6.864736557006836; Y := -2.6641697883605957; Z := 0.0}
            vector3{X := 6.864736557006836; Y := -3.6641697883605957; Z := 0.0}
            vector3{X := 24.286439895629883; Y := -3.6641697883605957; Z := 0.0}
            vector3{X := 24.286439895629883; Y := 0.059253692626953125; Z := 0.0}
            vector3{X := 17.46669578552246; Y := 0.059253692626953125; Z := 0.0}
            vector3{X := 24.286439895629883; Y := -6.799684047698975; Z := 0.0}
            vector3{X := 20.582612991333008; Y := -6.799684047698975; Z := 0.0}
            vector3{X := 20.582612991333008; Y := -3.6641697883605957; Z := 0.0}
            vector3{X := 17.447097778320312; Y := -3.6668128967285156; Z := 0.0}
            vector3{X := 19.231531143188477; Y := -3.6668128967285156; Z := 0.0}
            vector3{X := 17.447097778320312; Y := -17.79664421081543; Z := 0.0}
            vector3{X := 19.231531143188477; Y := -17.79664421081543; Z := 0.0}
            vector3{X := 6.808298110961914; Y := -17.79664421081543; Z := 0.0}
            vector3{X := 6.808298110961914; Y := -6.988527297973633; Z := 0.0}
            vector3{X := 17.447097778320312; Y := -6.988527297973633; Z := 0.0}
            vector3{X := 21.808366775512695; Y := -6.799684047698975; Z := 0.0}
            vector3{X := 23.723711013793945; Y := -6.799684047698975; Z := 0.0}
            vector3{X := 21.808366775512695; Y := -19.7996826171875; Z := 0.0}
            vector3{X := 23.723711013793945; Y := -19.7996826171875; Z := 0.0}
            vector3{X := 20.554391860961914; Y := -7.799684047698975; Z := 0.0}
            vector3{X := 20.554391860961914; Y := -19.7996826171875; Z := 0.0}
            vector3{X := 21.80393409729004; Y := -7.799684047698975; Z := 0.0}
            vector3{X := 23.722867965698242; Y := -7.799684047698975; Z := 0.0}
            vector3{X := 33.12000274658203; Y := -7.799684047698975; Z := 0.0}
            vector3{X := 24.286439895629883; Y := -2.95867919921875; Z := 0.0}
            vector3{X := 33.12000274658203; Y := -19.7996826171875; Z := 0.0}
            vector3{X := 24.286439895629883; Y := -4.34614372253418; Z := 0.0}
            vector3{X := 33.175621032714844; Y := -2.95867919921875; Z := 0.0}
            vector3{X := 33.175621032714844; Y := -4.34614372253418; Z := 0.0}
            vector3{X := 25.175622940063477; Y := 0.04132080078125; Z := 0.0}
            vector3{X := 25.175622940063477; Y := -2.95867919921875; Z := 0.0}
            vector3{X := 25.175622940063477; Y := -4.350979804992676; Z := 0.0}
            vector3{X := 25.175622940063477; Y := -6.956459045410156; Z := 0.0}
            vector3{X := 33.175621032714844; Y := -6.956459045410156; Z := 0.0}
            vector3{X := 33.175621032714844; Y := 0.04132080078125; Z := 0.0}
            vector3{X := 30.475618362426758; Y := -6.956459045410156; Z := 0.0}
            vector3{X := 31.875619888305664; Y := -6.956459045410156; Z := 0.0}
            vector3{X := 30.475618362426758; Y := -7.801551818847656; Z := 0.0}
            vector3{X := 31.875619888305664; Y := -7.801551818847656; Z := 0.0}
            vector3{X := -25.61294174194336; Y := 0.7031126022338867; Z := 0.0}
            vector3{X := -18.050079345703125; Y := 0.7031126022338867; Z := 0.0}
            vector3{X := -25.61294174194336; Y := 8.35063362121582; Z := 0.0}
            vector3{X := -18.050079345703125; Y := 8.35063362121582; Z := 0.0}
            vector3{X := -25.61294174194336; Y := -1.3192501068115234; Z := 0.0}
            vector3{X := -18.050079345703125; Y := -1.3192501068115234; Z := 0.0}
            vector3{X := -25.61294174194336; Y := -3.501612663269043; Z := 0.0}
            vector3{X := -18.050079345703125; Y := -3.501612663269043; Z := 0.0}
            vector3{X := -20.34403419494629; Y := 8.35063362121582; Z := 0.0}
            vector3{X := -18.305950164794922; Y := 8.35063362121582; Z := 0.0}
            vector3{X := -20.34403419494629; Y := 9.408868789672852; Z := 0.0}
            vector3{X := -18.305950164794922; Y := 9.408868789672852; Z := 0.0}
            vector3{X := -30.652040481567383; Y := 8.389827728271484; Z := 0.0}
            vector3{X := -28.613956451416016; Y := 8.389827728271484; Z := 0.0}
            vector3{X := -30.652040481567383; Y := 9.408868789672852; Z := 0.0}
            vector3{X := -28.613956451416016; Y := 9.408868789672852; Z := 0.0}
            vector3{X := -18.305950164794922; Y := 32.40886688232422; Z := 0.0}
            vector3{X := -40.59088897705078; Y := 32.40886688232422; Z := 0.0}
            vector3{X := -40.59088897705078; Y := 9.408868789672852; Z := 0.0}
            vector3{X := 17.669876098632812; Y := 11.458684921264648; Z := 0.0}
            vector3{X := 18.669876098632812; Y := 9.060014724731445; Z := 0.0}
            vector3{X := 18.669876098632812; Y := 11.458684921264648; Z := 0.0}
            vector3{X := 18.669876098632812; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 36.307151794433594; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 36.307151794433594; Y := 1.073857307434082; Z := 0.0}
            vector3{X := 18.726314544677734; Y := 1.073857307434082; Z := 0.0}
            vector3{X := 21.895631790161133; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 23.758127212524414; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 30.220422744750977; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 32.082923889160156; Y := 12.954326629638672; Z := 0.0}
            vector3{X := 30.220422744750977; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 32.082923889160156; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 21.895631790161133; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 23.758127212524414; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 27.220422744750977; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 27.220422744750977; Y := 24.395591735839844; Z := 0.0}
            vector3{X := 36.220428466796875; Y := 24.395591735839844; Z := 0.0}
            vector3{X := 36.220428466796875; Y := 13.9825439453125; Z := 0.0}
            vector3{X := 18.698095321655273; Y := 13.954324722290039; Z := 0.0}
            vector3{X := 18.698095321655273; Y := 24.452030181884766; Z := 0.0}
            vector3{X := 26.03672981262207; Y := 24.452030181884766; Z := 0.0}
            vector3{X := 26.03672981262207; Y := 13.982542037963867; Z := 0.0}
        PrevTriangles : []triangle = array:
            triangle{A := 3; B := 0; C := 2; Translation := vector3{X := -0.3321816623210907; Y := 0.3333333432674408; Z := 0.0}}
            triangle{A := 5; B := 6; C := 4; Translation := vector3{X := -1.8261507749557495; Y := 0.41156092286109924; Z := 0.0}}
            triangle{A := 3; B := 1; C := 0; Translation := vector3{X := 0.3344850242137909; Y := -0.3333333432674408; Z := 0.0}}
            triangle{A := 5; B := 7; C := 6; Translation := vector3{X := -2.652301549911499; Y := 0.27936795353889465; Z := 0.0}}
            triangle{A := 9; B := 8; C := 10; Translation := vector3{X := -1.9426484107971191; Y := -0.03303438052535057; Z := 0.0}}
            triangle{A := 10; B := 8; C := 7; Translation := vector3{X := -2.710550308227539; Y := 0.0570702850818634; Z := 0.0}}
            triangle{A := 11; B := 13; C := 12; Translation := vector3{X := -1.9426484107971191; Y := 0.807136595249176; Z := 0.0}}
            triangle{A := 11; B := 6; C := 13; Translation := vector3{X := -2.710550308227539; Y := 0.6754452586174011; Z := 0.0}}
            triangle{A := 16; B := 15; C := 13; Translation := vector3{X := -2.83500599861145; Y := 1.6779431104660034; Z := 0.0}}
            triangle{A := 13; B := 15; C := 14; Translation := vector3{X := -3.1567294597625732; Y := 2.417058229446411; Z := 0.0}}
            triangle{A := 18; B := 20; C := 17; Translation := vector3{X := -1.968877911567688; Y := 1.6141568422317505; Z := 0.0}}
            triangle{A := 20; B := 18; C := 19; Translation := vector3{X := -1.424472689628601; Y := 1.7292728424072266; Z := 0.0}}
            triangle{A := 19; B := 22; C := 23; Translation := vector3{X := -0.3023771643638611; Y := 1.955286979675293; Z := 0.0}}
            triangle{A := 19; B := 21; C := 22; Translation := vector3{X := 0.3085980713367462; Y := 1.7847219705581665; Z := 0.0}}
            triangle{A := 19; B := 21; C := 20; Translation := vector3{X := -0.2690922021865845; Y := 1.6141568422317505; Z := 0.0}}
            triangle{A := 24; B := 25; C := 27; Translation := vector3{X := 0.2973822057247162; Y := 1.328475832939148; Z := 0.0}}
            triangle{A := 27; B := 25; C := 26; Translation := vector3{X := 0.3997690975666046; Y := 1.1579108238220215; Z := 0.0}}
            triangle{A := 21; B := 28; C := 29; Translation := vector3{X := 0.8026242256164551; Y := 1.343743920326233; Z := 0.0}}
            triangle{A := 21; B := 27; C := 28; Translation := vector3{X := 0.6523901224136353; Y := 1.4213924407958984; Z := 0.0}}
            triangle{A := 30; B := 32; C := 22; Translation := vector3{X := 0.6115983128547668; Y := 2.4304187297821045; Z := 0.0}}
            triangle{A := 22; B := 32; C := 31; Translation := vector3{X := 0.7339739799499512; Y := 2.8501014709472656; Z := 0.0}}
            triangle{A := 22; B := 21; C := 33; Translation := vector3{X := 0.9187590479850769; Y := 1.8401708602905273; Z := 0.0}}
            triangle{A := 37; B := 35; C := 34; Translation := vector3{X := -0.6365818381309509; Y := 2.6439764499664307; Z := 0.0}}
            triangle{A := 37; B := 36; C := 35; Translation := vector3{X := -0.5341948866844177; Y := 2.2242937088012695; Z := 0.0}}
            triangle{A := 32; B := 37; C := 34; Translation := vector3{X := -0.22703413665294647; Y := 3.0636589527130127; Z := 0.0}}
            triangle{A := 38; B := 37; C := 32; Translation := vector3{X := 0.1825135499238968; Y := 2.857534170150757; Z := 0.0}}
            triangle{A := 42; B := 41; C := 39; Translation := vector3{X := 0.10120335966348648; Y := 4.388401508331299; Z := 0.0}}
            triangle{A := 39; B := 41; C := 40; Translation := vector3{X := 1.238134741783142; Y := 3.8290929794311523; Z := 0.0}}
            triangle{A := 40; B := 43; C := 45; Translation := vector3{X := 3.0093765258789062; Y := 3.7130725383758545; Z := 0.0}}
            triangle{A := 45; B := 43; C := 44; Translation := vector3{X := 3.6332848072052; Y := 4.156360149383545; Z := 0.0}}
            triangle{A := 44; B := 46; C := 48; Translation := vector3{X := 3.930044174194336; Y := 4.713358402252197; Z := 0.0}}
            triangle{A := 48; B := 46; C := 47; Translation := vector3{X := 3.5612881183624268; Y := 4.82706880569458; Z := 0.0}}
            triangle{A := 49; B := 50; C := 43; Translation := vector3{X := 3.694880247116089; Y := 2.8631582260131836; Z := 0.0}}
            triangle{A := 43; B := 50; C := 51; Translation := vector3{X := 3.0909597873687744; Y := 3.0664710998535156; Z := 0.0}}
            triangle{A := 53; B := 52; C := 54; Translation := vector3{X := 1.6055355072021484; Y := 1.2543669939041138; Z := 0.0}}
            triangle{A := 54; B := 52; C := 40; Translation := vector3{X := 2.015897512435913; Y := 2.262075662612915; Z := 0.0}}
            triangle{A := 50; B := 40; C := 51; Translation := vector3{X := 2.4670512676239014; Y := 3.0664710998535156; Z := 0.0}}
            triangle{A := 55; B := 40; C := 50; Translation := vector3{X := 2.4470489025115967; Y := 2.8631582260131836; Z := 0.0}}
            triangle{A := 56; B := 59; C := 57; Translation := vector3{X := 3.038952589035034; Y := 1.6111783981323242; Z := 0.0}}
            triangle{A := 57; B := 59; C := 58; Translation := vector3{X := 3.653273820877075; Y := 1.9523082971572876; Z := 0.0}}
            triangle{A := 61; B := 60; C := 63; Translation := vector3{X := 3.2476131916046143; Y := 2.4158847332000732; Z := 0.0}}
            triangle{A := 63; B := 60; C := 62; Translation := vector3{X := 3.710482358932495; Y := 2.5383307933807373; Z := 0.0}}
            triangle{A := 59; B := 67; C := 68; Translation := vector3{X := 4.6167216300964355; Y := 1.5797287225723267; Z := 0.0}}
            triangle{A := 59; B := 66; C := 67; Translation := vector3{X := 4.965847492218018; Y := 1.368033528327942; Z := 0.0}}
            triangle{A := 65; B := 66; C := 59; Translation := vector3{X := 4.073970794677734; Y := 1.1563383340835571; Z := 0.0}}
            triangle{A := 65; B := 59; C := 64; Translation := vector3{X := 3.182093381881714; Y := 1.2131932973861694; Z := 0.0}}
            triangle{A := 70; B := 66; C := 71; Translation := vector3{X := 4.935750961303711; Y := 0.9212136268615723; Z := 0.0}}
            triangle{A := 70; B := 69; C := 66; Translation := vector3{X := 5.125362396240234; Y := 0.7429440021514893; Z := 0.0}}
            triangle{A := 72; B := 75; C := 73; Translation := vector3{X := 4.4472880363464355; Y := 0.2956808805465698; Z := 0.0}}
            triangle{A := 72; B := 74; C := 75; Translation := vector3{X := 4.355936527252197; Y := -0.5076707601547241; Z := 0.0}}
            triangle{A := 76; B := 78; C := 74; Translation := vector3{X := 3.7199485301971436; Y := -0.696526825428009; Z := 0.0}}
            triangle{A := 76; B := 77; C := 78; Translation := vector3{X := 3.175311326980591; Y := -0.08203128725290298; Z := 0.0}}
            triangle{A := 81; B := 80; C := 82; Translation := vector3{X := 5.130496978759766; Y := -0.9135558009147644; Z := 0.0}}
            triangle{A := 81; B := 79; C := 80; Translation := vector3{X := 5.032444000244141; Y := -0.17444072663784027; Z := 0.0}}
            triangle{A := 84; B := 83; C := 81; Translation := vector3{X := 4.806000232696533; Y := -0.9704108238220215; Z := 0.0}}
            triangle{A := 85; B := 81; C := 83; Translation := vector3{X := 4.869968891143799; Y := -0.28815075755119324; Z := 0.0}}
            triangle{A := 82; B := 87; C := 89; Translation := vector3{X := 6.19060754776001; Y := -0.9704108238220215; Z := 0.0}}
            triangle{A := 87; B := 82; C := 86; Translation := vector3{X := 5.709535598754883; Y := -0.28815075755119324; Z := 0.0}}
            triangle{A := 92; B := 88; C := 91; Translation := vector3{X := 6.2251105308532715; Y := 1.1409311294555664; Z := 0.0}}
            triangle{A := 92; B := 90; C := 88; Translation := vector3{X := 5.770042419433594; Y := 1.062046766281128; Z := 0.0}}
            triangle{A := 93; B := 98; C := 94; Translation := vector3{X := 5.861082553863525; Y := 1.5609453916549683; Z := 0.0}}
            triangle{A := 91; B := 94; C := 98; Translation := vector3{X := 6.270630359649658; Y := 1.3903803825378418; Z := 0.0}}
            triangle{A := 97; B := 96; C := 92; Translation := vector3{X := 6.270630359649658; Y := 0.6863434910774231; Z := 0.0}}
            triangle{A := 92; B := 96; C := 95; Translation := vector3{X := 5.861082553863525; Y := 0.8344780802726746; Z := 0.0}}
            triangle{A := 100; B := 99; C := 102; Translation := vector3{X := 6.408853054046631; Y := 0.48988619446754456; Z := 0.0}}
            triangle{A := 101; B := 102; C := 99; Translation := vector3{X := 6.337181568145752; Y := 0.44183841347694397; Z := 0.0}}
            triangle{A := 104; B := 106; C := 103; Translation := vector3{X := -1.5742536783218384; Y := 2.279188871383667; Z := 0.0}}
            triangle{A := 103; B := 106; C := 105; Translation := vector3{X := -1.9614229202270508; Y := 2.7139885425567627; Z := 0.0}}
            triangle{A := 108; B := 109; C := 110; Translation := vector3{X := -1.5742536783218384; Y := 1.2512881755828857; Z := 0.0}}
            triangle{A := 108; B := 107; C := 109; Translation := vector3{X := -1.9614229202270508; Y := 1.3753663301467896; Z := 0.0}}
            triangle{A := 115; B := 118; C := 117; Translation := vector3{X := -3.0181620121002197; Y := 3.2713489532470703; Z := 0.0}}
            triangle{A := 115; B := 116; C := 118; Translation := vector3{X := -2.913825750350952; Y := 3.213411331176758; Z := 0.0}}
            triangle{A := 112; B := 111; C := 114; Translation := vector3{X := -1.3307180404663086; Y := 3.2089545726776123; Z := 0.0}}
            triangle{A := 114; B := 111; C := 113; Translation := vector3{X := -1.4350546598434448; Y := 3.269120454788208; Z := 0.0}}
            triangle{A := 117; B := 120; C := 121; Translation := vector3{X := -4.140106678009033; Y := 4.636951446533203; Z := 0.0}}
            triangle{A := 117; B := 119; C := 120; Translation := vector3{X := -2.9992637634277344; Y := 5.944616317749023; Z := 0.0}}
            triangle{A := 114; B := 119; C := 117; Translation := vector3{X := -1.858420491218567; Y := 4.636951446533203; Z := 0.0}}
            triangle{A := 122; B := 43; C := 124; Translation := vector3{X := 4.3499932289123535; Y := 3.542536973953247; Z := 0.0}}
            triangle{A := 124; B := 43; C := 123; Translation := vector3{X := 4.401186943054199; Y := 3.406160593032837; Z := 0.0}}
            triangle{A := 128; B := 127; C := 123; Translation := vector3{X := 5.358182430267334; Y := 2.361678123474121; Z := 0.0}}
            triangle{A := 123; B := 127; C := 126; Translation := vector3{X := 6.258206844329834; Y := 3.037142038345337; Z := 0.0}}
            triangle{A := 123; B := 126; C := 124; Translation := vector3{X := 5.355293273925781; Y := 3.6275718212127686; Z := 0.0}}
            triangle{A := 124; B := 126; C := 125; Translation := vector3{X := 5.355293273925781; Y := 3.848982810974121; Z := 0.0}}
            triangle{A := 129; B := 136; C := 135; Translation := vector3{X := 5.043140888214111; Y := 4.047727584838867; Z := 0.0}}
            triangle{A := 136; B := 129; C := 130; Translation := vector3{X := 5.138488292694092; Y := 3.990872383117676; Z := 0.0}}
            triangle{A := 131; B := 134; C := 133; Translation := vector3{X := 6.321665287017822; Y := 4.047727584838867; Z := 0.0}}
            triangle{A := 131; B := 132; C := 134; Translation := vector3{X := 6.417013168334961; Y := 3.990872383117676; Z := 0.0}}
            triangle{A := 134; B := 139; C := 140; Translation := vector3{X := 6.93598747253418; Y := 4.699825286865234; Z := 0.0}}
            triangle{A := 134; B := 138; C := 139; Translation := vector3{X := 6.475246429443359; Y := 5.291859149932861; Z := 0.0}}
            triangle{A := 137; B := 138; C := 134; Translation := vector3{X := 6.014504909515381; Y := 4.698220729827881; Z := 0.0}}
            triangle{A := 136; B := 143; C := 144; Translation := vector3{X := 5.467134952545166; Y := 4.703033924102783; Z := 0.0}}
            triangle{A := 136; B := 142; C := 143; Translation := vector3{X := 5.091444492340088; Y := 5.298276424407959; Z := 0.0}}
            triangle{A := 136; B := 142; C := 135; Translation := vector3{X := 4.8794474601745605; Y := 4.70142936706543; Z := 0.0}}
            triangle{A := 142; B := 141; C := 135; Translation := vector3{X := 4.6204071044921875; Y := 4.70142936706543; Z := 0.0}}
        
        # Scaling and offsetting.
        
        Scale := 1.0
        Offset := vector3{}
        
        Vertices := for (Vertex : PrevVertices):
            Vertex * Scale + Offset
        Triangles := for (Triangle : PrevTriangles):
            triangle:
                A := Triangle.A
                B := Triangle.B
                C := Triangle.C
                Translation := Triangle.Translation * Scale + Offset
        
        if:
            A := Triangles[0]
            B := Triangles[1]
            C := Triangles[2]
            D := Triangles[3]
            E := Triangles[4]
            F := Triangles[5]
            G := Triangles[6]
            H := Triangles[7]
            I := Triangles[8]
            J := Triangles[9]
            K := Triangles[10]
            L := Triangles[11]
            M := Triangles[12]
            N := Triangles[13]
            O := Triangles[14]
            P := Triangles[15]
            Q := Triangles[16]
            R := Triangles[17]
            S := Triangles[18]
            T := Triangles[19]
            U := Triangles[20]
            V := Triangles[21]
            W := Triangles[22]
            X := Triangles[23]
            Y := Triangles[24]
            Z := Triangles[25]
            AA := Triangles[26]
            AB := Triangles[27]
            AC := Triangles[28]
            AD := Triangles[29]
            AE := Triangles[30]
            AF := Triangles[31]
            AG := Triangles[32]
            AH := Triangles[33]
            AI := Triangles[34]
            AJ := Triangles[35]
            AK := Triangles[36]
            AL := Triangles[37]
            AM := Triangles[38]
            AN := Triangles[39]
            AO := Triangles[40]
            AP := Triangles[41]
            AQ := Triangles[42]
            AR := Triangles[43]
            AS := Triangles[44]
            AT := Triangles[45]
            AU := Triangles[46]
            AV := Triangles[47]
            AW := Triangles[48]
            AX := Triangles[49]
            AY := Triangles[50]
            AZ := Triangles[51]
            BA := Triangles[52]
            BB := Triangles[53]
            BC := Triangles[54]
            BD := Triangles[55]
            BE := Triangles[56]
            BF := Triangles[57]
            BG := Triangles[58]
            BH := Triangles[59]
            BI := Triangles[60]
            BJ := Triangles[61]
            BK := Triangles[62]
            BL := Triangles[63]
            BM := Triangles[64]
            BN := Triangles[65]
            BO := Triangles[66]
            BP := Triangles[67]
            BQ := Triangles[68]
            BR := Triangles[69]
            BS := Triangles[70]
            BT := Triangles[71]
            BU := Triangles[72]
            BV := Triangles[73]
            BW := Triangles[74]
            BX := Triangles[75]
            BY := Triangles[76]
            BZ := Triangles[77]
            CA := Triangles[78]
            CB := Triangles[79]
            CC := Triangles[80]
            CD := Triangles[81]
            CE := Triangles[82]
            CF := Triangles[83]
            CG := Triangles[84]
            CH := Triangles[85]
            CI := Triangles[86]
            CJ := Triangles[87]
            CK := Triangles[88]
            CL := Triangles[89]
            CM := Triangles[90]
            CN := Triangles[91]
            CO := Triangles[92]
            CP := Triangles[93]
        then:
            A.SetNeighbors(map{C => edge{Left := 0; Right := 3}});
            B.SetNeighbors(map{D => edge{Left := 6; Right := 5}}); 
            C.SetNeighbors(map{A => edge{Left := 0; Right := 3}}); 
            D.SetNeighbors(map{B => edge{Left := 6; Right := 5}}); 
            E.SetNeighbors(map{F => edge{Left := 8; Right := 10}}); 
            F.SetNeighbors(map{E => edge{Left := 8; Right := 10}}); 
            G.SetNeighbors(map{H => edge{Left := 13; Right := 11}}); 
            H.SetNeighbors(map{G => edge{Left := 13; Right := 11}}); 
            I.SetNeighbors(map{J => edge{Left := 15; Right := 13}}); 
            J.SetNeighbors(map{I => edge{Left := 15; Right := 13}}); 
            K.SetNeighbors(map{L => edge{Left := 18; Right := 20}}); 
            L.SetNeighbors(map{K => edge{Left := 18; Right := 20}; O => edge{Left := 19; Right := 20}}); 
            M.SetNeighbors(map{N => edge{Left := 22; Right := 19}}); 
            N.SetNeighbors(map{M => edge{Left := 22; Right := 19}; O => edge{Left := 19; Right := 21}; V => edge{Left := 22; Right := 21}}); 
            O.SetNeighbors(map{L => edge{Left := 19; Right := 20}; N => edge{Left := 19; Right := 21}}); 
            P.SetNeighbors(map{Q => edge{Left := 27; Right := 25}}); 
            Q.SetNeighbors(map{P => edge{Left := 27; Right := 25}}); 
            R.SetNeighbors(map{S => edge{Left := 28; Right := 21}}); 
            S.SetNeighbors(map{R => edge{Left := 28; Right := 21}}); 
            T.SetNeighbors(map{U => edge{Left := 32; Right := 22}}); 
            U.SetNeighbors(map{T => edge{Left := 32; Right := 22}}); 
            V.SetNeighbors(map{N => edge{Left := 22; Right := 21}}); 
            W.SetNeighbors(map{X => edge{Left := 37; Right := 35}; Y => edge{Left := 34; Right := 37}}); 
            X.SetNeighbors(map{W => edge{Left := 37; Right := 35}}); 
            Y.SetNeighbors(map{W => edge{Left := 34; Right := 37}; Z => edge{Left := 32; Right := 37}}); 
            Z.SetNeighbors(map{Y => edge{Left := 32; Right := 37}}); 
            AA.SetNeighbors(map{AB => edge{Left := 41; Right := 39}}); 
            AB.SetNeighbors(map{AA => edge{Left := 41; Right := 39}}); 
            AC.SetNeighbors(map{AD => edge{Left := 43; Right := 45}}); 
            AD.SetNeighbors(map{AC => edge{Left := 43; Right := 45}}); 
            AE.SetNeighbors(map{AF => edge{Left := 48; Right := 46}}); 
            AF.SetNeighbors(map{AE => edge{Left := 48; Right := 46}}); 
            AG.SetNeighbors(map{AH => edge{Left := 43; Right := 50}}); 
            AH.SetNeighbors(map{AG => edge{Left := 43; Right := 50}; AK => edge{Left := 50; Right := 51}}); 
            AI.SetNeighbors(map{AJ => edge{Left := 52; Right := 54}}); 
            AJ.SetNeighbors(map{AI => edge{Left := 52; Right := 54}}); 
            AK.SetNeighbors(map{AH => edge{Left := 50; Right := 51}; AL => edge{Left := 50; Right := 40}}); 
            AL.SetNeighbors(map{AK => edge{Left := 50; Right := 40}}); 
            AM.SetNeighbors(map{AN => edge{Left := 59; Right := 57}}); 
            AN.SetNeighbors(map{AM => edge{Left := 59; Right := 57}}); 
            AO.SetNeighbors(map{AP => edge{Left := 60; Right := 63}}); 
            AP.SetNeighbors(map{AO => edge{Left := 60; Right := 63}}); 
            AQ.SetNeighbors(map{AR => edge{Left := 59; Right := 67}}); 
            AR.SetNeighbors(map{AQ => edge{Left := 59; Right := 67}; AS => edge{Left := 59; Right := 66}}); 
            AS.SetNeighbors(map{AR => edge{Left := 59; Right := 66}; AT => edge{Left := 65; Right := 59}}); 
            AT.SetNeighbors(map{AS => edge{Left := 65; Right := 59}}); 
            AU.SetNeighbors(map{AV => edge{Left := 70; Right := 66}}); 
            AV.SetNeighbors(map{AU => edge{Left := 70; Right := 66}}); 
            AW.SetNeighbors(map{AX => edge{Left := 75; Right := 72}}); 
            AX.SetNeighbors(map{AW => edge{Left := 75; Right := 72}}); 
            AY.SetNeighbors(map{AZ => edge{Left := 76; Right := 78}}); 
            AZ.SetNeighbors(map{AY => edge{Left := 76; Right := 78}}); 
            BA.SetNeighbors(map{BB => edge{Left := 81; Right := 80}}); 
            BB.SetNeighbors(map{BA => edge{Left := 81; Right := 80}}); 
            BC.SetNeighbors(map{BD => edge{Left := 81; Right := 83}}); 
            BD.SetNeighbors(map{BC => edge{Left := 81; Right := 83}}); 
            BE.SetNeighbors(map{BF => edge{Left := 82; Right := 87}}); 
            BF.SetNeighbors(map{BE => edge{Left := 82; Right := 87}}); 
            BG.SetNeighbors(map{BH => edge{Left := 88; Right := 92}}); 
            BH.SetNeighbors(map{BG => edge{Left := 88; Right := 92}}); 
            BI.SetNeighbors(map{BJ => edge{Left := 94; Right := 98}}); 
            BJ.SetNeighbors(map{BI => edge{Left := 94; Right := 98}}); 
            BK.SetNeighbors(map{BL => edge{Left := 96; Right := 92}}); 
            BL.SetNeighbors(map{BK => edge{Left := 96; Right := 92}}); 
            BM.SetNeighbors(map{BN => edge{Left := 102; Right := 99}}); 
            BN.SetNeighbors(map{BM => edge{Left := 102; Right := 99}}); 
            BO.SetNeighbors(map{BP => edge{Left := 106; Right := 103}}); 
            BP.SetNeighbors(map{BO => edge{Left := 106; Right := 103}}); 
            BQ.SetNeighbors(map{BR => edge{Left := 108; Right := 109}}); 
            BR.SetNeighbors(map{BQ => edge{Left := 108; Right := 109}}); 
            BS.SetNeighbors(map{BT => edge{Left := 118; Right := 115}}); 
            BT.SetNeighbors(map{BS => edge{Left := 118; Right := 115}}); 
            BU.SetNeighbors(map{BV => edge{Left := 114; Right := 111}}); 
            BV.SetNeighbors(map{BU => edge{Left := 114; Right := 111}}); 
            BW.SetNeighbors(map{BX => edge{Left := 120; Right := 117}}); 
            BX.SetNeighbors(map{BW => edge{Left := 120; Right := 117}; BY => edge{Left := 119; Right := 117}}); 
            BY.SetNeighbors(map{BX => edge{Left := 119; Right := 117}}); 
            BZ.SetNeighbors(map{CA => edge{Left := 43; Right := 124}}); 
            CA.SetNeighbors(map{BZ => edge{Left := 43; Right := 124}; CD => edge{Left := 123; Right := 124}}); 
            CB.SetNeighbors(map{CC => edge{Left := 127; Right := 123}}); 
            CC.SetNeighbors(map{CB => edge{Left := 127; Right := 123}; CD => edge{Left := 126; Right := 123}}); 
            CD.SetNeighbors(map{CA => edge{Left := 123; Right := 124}; CC => edge{Left := 126; Right := 123}; CE => edge{Left := 126; Right := 124}}); 
            CE.SetNeighbors(map{CD => edge{Left := 126; Right := 124}}); 
            CF.SetNeighbors(map{CG => edge{Left := 129; Right := 136}; CO => edge{Left := 136; Right := 135}}); 
            CG.SetNeighbors(map{CF => edge{Left := 129; Right := 136}}); 
            CH.SetNeighbors(map{CI => edge{Left := 131; Right := 134}}); 
            CI.SetNeighbors(map{CH => edge{Left := 131; Right := 134}}); 
            CJ.SetNeighbors(map{CK => edge{Left := 134; Right := 139}}); 
            CK.SetNeighbors(map{CJ => edge{Left := 134; Right := 139}; CL => edge{Left := 134; Right := 138}}); 
            CL.SetNeighbors(map{CK => edge{Left := 134; Right := 138}});
            CM.SetNeighbors(map{CN => edge{Left := 136; Right := 143}});
            CN.SetNeighbors(map{CM => edge{Left := 136; Right := 143}; CO => edge{Left := 136; Right := 142}}); 
            CO.SetNeighbors(map{CF => edge{Left := 136; Right := 135}; CN => edge{Left := 136; Right := 142}; CP => edge{Left := 135; Right := 142}}); 
            CP.SetNeighbors(map{CO => edge{Left := 135; Right := 142}});
        
            NewNavmesh := navmesh{Vertices := Vertices; Triangles := Triangles}

            # Draw the navigation mesh during gameplay.
            NewNavmesh.Draw()

            # Update the navmesh.
            set Navmesh = NewNavmesh

    StartUnnamedAgent<private>() : void =
        InitialTranslation := vector3{X := 2048.0; Y := 256.0; Z := 16.0}
        UnnamedAgent.Start(InitialTranslation)
    
    GetNavmesh<public>()<transacts> : navmesh = Navmesh
