require "widgets"
local sampev = require('lib.samp.events')
local sf = require("sampfuncs")
local ffi = require('ffi')
local imgui = require 'mimgui'
local memory = require 'memory'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local new = imgui.new
local tabbb = 1
local interiorr = false
local checkbox = new.bool(false)
local bruteMin = new.int(1)
local bruteMax = new.int(1000)
local bruteDelay = new.int(100)
local bruteEnabled = false
local brutePaused = false
local bruteCurrent = 0
local WARNING_BLOCK = false
local skywalk = false
local floodalt = false
local checkboxx = new.bool(false)
local syncKey = false
local flood = false
local offcomand = false
local offcomande = false
local pickups = {}
local tramplin = false


local inicfg = require 'inicfg'
local iniFile = 'KoriCheat.ini'
local ini = inicfg.load({
	cfg = {
		theme = 8,
		style = 1
	},
    render = {
        nark = false,
        olen = false,
        gun = false,
        klad = false,
        ruda = false,
        len = false,
        hlopok = false,
        graf = false,
        xye = false
    },
    piz = {
        one = "4.0",
        two = "4.0",
        three = "4.0",
        four = "4.0",
        five = "4.0",
        six = "10.0",
        seven = "0.2",
        eight = "0.2",
        nine = "0",
        ten = "0",
        eleven = "0",
        twelve = "0",
        delay = "20",
        dist = "10"
    },
    mcheat = {    
        antistun = false,
        killbots = false,
        infrun = false,
        wallhack = false,
        noreload = false,
        nofall = false,
        blockdruganim = false,
        gmp = false,
        damage = "100",
        gethp = false,
        godcar = false,
        gmkolesa = false,
        infinityfuel = false,
        heliblades = false,
        ash = false,
        andb = false,
        infpt = false,
        setskill = false,
        pcar = false,
        antistuun = false,
        anticapt = false,
        antiafk = false,
        inter = false,
        interr = 0,
        textdraw = "0",
        pickup = "0",
        surf = false,
        anticarskill = false,
        antistuuun = false,
        antilomka = false,
        skipzz = false,
        antieject = false,
        antiplayer = false,
        antimask = false,
        antidrop = false,
        RC = "0",
        antiogranichitel = false,
        maxdamage = false,
        doubleDamage = false,
        tripleDamage = false,
        badSync = true,
        badSyncWarnings = true,
        skycoordX = 0.8,
        skycoordY = 0,
        skycoordZ = 0.5,
        jumpcar = false,
        nobike = false,
        rglaz = false,
        rglazz = "101",
        bigdamage = false,
        speedhack = false,
        hp = false,
        speed = false,
        carsit = false,
        carpas = false,
        cardelay = false
        },
        rapid = {
            rapidx = false,
            rapidxx = false,
            rapidxxx = false,
            rapidxxxx = false,
            rapidxxxxx = false,
            rapidxxxxxx = false,
            rapidxxxxxxx = false,
            rapidxxxxxxxx = false,
            rapidxxxxxxxxx = false,
            rapidxxxxxxxxxx = false
        },
        fastbeg = {
            begx = false,
            begxx = false,
            begxxx = false,
            begxxxx = false,
            begxxxxx = false,
            begxxxxxx = false,
            begxxxxxxx = false,
            begxxxxxxxx = false,
            begxxxxxxxxx = false,
            begxxxxxxxxxx = false
        },
        antiadm = {
            antidmg = false,
            logTextdraws = false,
            setplayerpos = false,
            nott = false,
            nodialog = false,
            fix = false,
            PickedUpPickup = false,
            showpickup = false,
            showtextdraww = false,
        },
        flooder = {
            delay1 = "0",
            flood = false,
            text = "Text",
            delayy = "0",
            floodd = false,
            textt = "Text",
            delayyy = "0",
            flooddd = false,
            texttt = "Text"
        }
}, iniFile)
inicfg.save(ini, iniFile)

local badSync = new.bool(ini.mcheat.badSync)
local badSyncWarnings = new.bool(ini.mcheat.badSyncWarnings)

local lol = {
    showpickup = new.bool(ini.antiadm.showpickup),
    showtextdraww = new.bool(ini.antiadm.showtextdraww),
    nark = new.bool(ini.render.nark),
    olen = new.bool(ini.render.olen),
    gun = new.bool(ini.render.gun),
    klad = new.bool(ini.render.klad),
    damage = ini.mcheat.damage,
    ruda = new.bool(ini.render.ruda),
    len = new.bool(ini.render.len),
    hlopok = new.bool(ini.render.hlopok),
    graf = new.bool(ini.render.graf),
    xye = new.bool(ini.render.xye),
    one = new.float(ini.piz.one),
    two = new.float(ini.piz.two),
    three = new.float(ini.piz.three),
    four = new.float(ini.piz.four),
    five = new.float(ini.piz.five),
    six = new.float(ini.piz.six),
    seven = new.float(ini.piz.seven),
    eight = new.float(ini.piz.eight),
    nine = new.float(ini.piz.nine),
    ten = new.float(ini.piz.ten),
    eleven = new.float(ini.piz.eleven),
    twelve = new.float(ini.piz.twelve),
    delay = new.float(ini.piz.delay),
    dist = new.float(ini.piz.dist),
    antistun = new.bool(ini.mcheat.antistun),
    infrun = new.bool(ini.mcheat.infrun),
    noreload = new.bool(ini.mcheat.noreload),
    nofall = new.bool(ini.mcheat.nofall),
    blockdruganim = new.bool(ini.mcheat.blockdruganim),
    gmp = new.bool(ini.mcheat.gmp),
    gethp = new.bool(ini.mcheat.gethp),
    godcar = new.bool(ini.mcheat.godcar),
    gmkolesa = new.bool(ini.mcheat.gmkolesa),
    infinityfuel = new.bool(ini.mcheat.infinityfuel),
    heliblades = new.bool(ini.mcheat.heliblades),
    ash = new.bool(ini.mcheat.ash),
    andb = new.bool(ini.mcheat.andb),
    infpt = new.bool(ini.mcheat.infpt),
    setskill = new.bool(ini.mcheat.setskill),
    pcar = new.bool(ini.mcheat.pcar),
    antistuun = new.bool(ini.mcheat.antistuun),
    anticapt = new.bool(ini.mcheat.anticapt),
    inter = new.bool(ini.mcheat.inter),
    interr = new.int(ini.mcheat.interr),
    textdraw = new.int(ini.mcheat.textdraw),
    pickup = new.int(ini.mcheat.pickup),
    surf = new.bool(ini.mcheat.surf),
    anticarskill = new.bool(ini.mcheat.anticarskill),
    antistuuun = new.bool(ini.mcheat.antistuuun),
    antilomka = new.bool(ini.mcheat.antilomka),
    skipzz = new.bool(ini.mcheat.skipzz),
    killbots = new.bool(ini.mcheat.killbots),
    antieject = new.bool(ini.mcheat.antieject),
    antiplayer = new.bool(ini.mcheat.antiplayer),
    antimask = new.bool(ini.mcheat.antimask),
    antidrop = new.bool(ini.mcheat.antidrop),
    RC = new.int(ini.mcheat.RC),
    antiogranichitel = new.bool(ini.mcheat.antiogranichitel),
    maxdamage = new.bool(ini.mcheat.maxdamage),
    doubleDamage = new.bool(ini.mcheat.doubleDamage),
    tripleDamage = new.bool(ini.mcheat.tripleDamage),
    rapidx = new.bool(ini.rapid.rapidx),
    rapidxx = new.bool(ini.rapid.rapidxx),
    rapidxxx = new.bool(ini.rapid.rapidxxx),
    rapidxxxx = new.bool(ini.rapid.rapidxxxx),
    rapidxxxxx = new.bool(ini.rapid.rapidxxxxx),
    rapidxxxxxx = new.bool(ini.rapid.rapidxxxxxx),
    rapidxxxxxxx = new.bool(ini.rapid.rapidxxxxxxx),
    rapidxxxxxxxx = new.bool(ini.rapid.rapidxxxxxxxx),
    rapidxxxxxxxxx = new.bool(ini.rapid.rapidxxxxxxxxx),
    rapidxxxxxxxxxx = new.bool(ini.rapid.rapidxxxxxxxxxx),
    begx = new.bool(ini.fastbeg.begx),
    begxx = new.bool(ini.fastbeg.begxx),
    begxxx = new.bool(ini.fastbeg.begxxx),
    begxxxx = new.bool(ini.fastbeg.begxxxx),
    begxxxxx = new.bool(ini.fastbeg.begxxxxx),
    begxxxxxx = new.bool(ini.fastbeg.begxxxxxx),
    begxxxxxxx = new.bool(ini.fastbeg.begxxxxxxx),
    begxxxxxxxx = new.bool(ini.fastbeg.begxxxxxxxx),
    begxxxxxxxxx = new.bool(ini.fastbeg.begxxxxxxxxx),
    begxxxxxxxxxx = new.bool(ini.fastbeg.begxxxxxxxxxx),
    antidmg = new.bool(ini.antiadm.antidmg),
    logTextdraws = new.bool(ini.antiadm.logTextdraws),
    setplayerpos = new.bool(ini.antiadm.setplayerpos),
    nott = new.bool(ini.antiadm.nott),
    nodialog = new.bool(ini.antiadm.nodialog),
    fix = new.bool(ini.antiadm.fix),
    delay1 = new.int(ini.flooder.delay1),
    flood = new.bool(false),
    text = new.char[64](ini.flooder.text),
    delayy = new.int(ini.flooder.delayy),
    floodd = new.bool(false),
    textt = new.char[64](ini.flooder.textt),
    delayyy = new.int(ini.flooder.delayyy),
    flooddd = new.bool(false),
    texttt = new.char[64](ini.flooder.texttt),
    wallhack = new.bool(ini.mcheat.wallhack),
    PickedUpPickup = new.bool(ini.antiadm.PickedUpPickup),
    jumpcar = new.bool(ini.mcheat.jumpcar),
    nobike = new.bool(ini.mcheat.nobike),
    rglaz = new.bool(ini.mcheat.rglaz),
    rglazz = new.float(ini.mcheat.rglazz),
    bigdamage = new.bool(ini.mcheat.bigdamage),
    damager = new.bool(false),
    damagerr = new.bool(false),
    speedhack = new.bool(ini.mcheat.speedhack),
    speed = new.float(ini.mcheat.speed),
    hp = new.bool(ini.mcheat.hp),
    clientconnect = new.bool(false),
    version = new.char[64]("0"),
    mod = new.char[64]("0"),
    nickname = new.char[64]("0"),
    challengeResponse = new.char[64]("0"),
    joinAuthKey = new.char[64]("0"),
    clientVer = new.char[64]("0"),
    challengeResponse2 = new.char[64]("0"),
    destroy = new.bool(false),
    lagger = new.bool(false),
    volent = new.bool(false),
    carsit = new.bool(ini.mcheat.carsit),
    cardelay = new.float(ini.mcheat.cardelay),
    carpas = new.bool(ini.mcheat.carpas),
    move = new.bool(false)
}

local samplua = {
    onSendEnterVehicle = new.bool(false),
    onSendClickPlayer= new.bool(false),
    onSendClientJoin = new.bool(false),
    onSendEnterEditObject = new.bool(false),
    onSendCommand = new.bool(false),
    onSendSpawn = new.bool(false),
    onSendDeathNotification = new.bool(false),
    onSendDialogResponse = new.bool(false),
    onSendClickTextDraw = new.bool(false),
    onSendVehicleTuningNotification = new.bool(false),
    onSendChat = new.bool(false),
    onSendClientCheckResponse = new.bool(false),
    onSendVehicleDamaged = new.bool(false),
    onSendEditAttachedObject = new.bool(false),
    onSendEditObject = new.bool(false),
    onSendInteriorChangeNotification = new.bool(false),
    onSendMapMarker = new.bool(false),
    onSendRequestClass = new.bool(false),
    onSendRequestSpawn = new.bool(false),
    onSendPickedUpPickup = new.bool(false),
    onSendMenuSelect = new.bool(false),
    onSendVehicleDestroyed = new.bool(false),
    onSendQuitMenu = new.bool(false),
    onSendExitVehicle = new.bool(false),
    onSendUpdateScoresAndPings = new.bool(false),
    onSendGiveDamage = new.bool(false),
    onSendTakeDamage = new.bool(false),
    onSendMoneyIncreaseNotification = new.bool(false),
    onSendNPCJoin = new.bool(false),
    onSendServerStatisticsRequest = new.bool(false),
    onSendPickedUpWeapon = new.bool(false),
    onSendCameraTargetUpdate = new.bool(false),
    onSendGiveActorDamage = new.bool(false),
    onInitGame = new.bool(false),
    onPlayerJoin = new.bool(false),
    onPlayerQuit = new.bool(false),
    onRequestClassResponse = new.bool(false),
    onRequestSpawnResponse = new.bool(false),
    onSetPlayerName = new.bool(false),
    onSetPlayerPos = new.bool(false),
    onSetPlayerPosFindZ = new.bool(false),
    onSetPlayerHealth = new.bool(false),
    onTogglePlayerControllable = new.bool(false),
    onPlaySound = new.bool(false),
    onSetWorldBounds = new.bool(false),
    onGivePlayerMoney = new.bool(false),
    onSetPlayerFacingAngle = new.bool(false),
    onResetPlayerMoney = new.bool(false),
    onResetPlayerWeapons = new.bool(false),
    onGivePlayerWeapon = new.bool(false),
    onCancelEdit = new.bool(false),
    onSetPlayerTime = new.bool(false),
    onSetToggleClock = new.bool(false),
    onPlayerStreamIn = new.bool(false),
    onSetShopName = new.bool(false),
    onSetPlayerSkillLevel = new.bool(false),
    onSetPlayerDrunk = new.bool(false),
    onCreate3DText = new.bool(false),
    onDisableCheckpoint = new.bool(false),
    onSetRaceCheckpoint = new.bool(false),
    onDisableRaceCheckpoint = new.bool(false),
    onGamemodeRestart = new.bool(false),
    onPlayAudioStream = new.bool(false),
    onStopAudioStream = new.bool(false),
    onRemoveBuilding = new.bool(false),
    onCreateObject = new.bool(false),
    onSetObjectPosition = new.bool(false),
    onSetObjectRotation = new.bool(false),
    onDestroyObject = new.bool(false),
    onPlayerDeathNotification = new.bool(false),
    onSetMapIcon = new.bool(false),
    onRemoveVehicleComponent = new.bool(false),
    onRemove3DTextLabel = new.bool(false),
    onPlayerChatBubble = new.bool(false),
    onUpdateGlobalTimer = new.bool(false),
    onShowDialog = new.bool(false),
    onDestroyPickup = new.bool(false),
    onLinkVehicleToInterior = new.bool(false),
    onSetPlayerArmour = new.bool(false),
    onSetPlayerArmedWeapon = new.bool(false),
    onSetSpawnInfo = new.bool(false),
    onSetPlayerTeam = new.bool(false),
    onPutPlayerInVehicle = new.bool(false),
    onRemovePlayerFromVehicle = new.bool(false),
    onSetPlayerColor = new.bool(false),
    onDisplayGameText = new.bool(false),
    onForceClassSelection = new.bool(false),
    onAttachObjectToPlayer = new.bool(false),
    onInitMenu = new.bool(false),
    onShowMenu = new.bool(false),
    onHideMenu = new.bool(false),
    onCreateExplosion = new.bool(false),
    onShowPlayerNameTag = new.bool(false),
    onAttachCameraToObject = new.bool(false),
    onInterpolateCamera = new.bool(false),
    onGangZoneStopFlash = new.bool(false),
    onApplyPlayerAnimation = new.bool(false),
    onClearPlayerAnimation = new.bool(false),
    onSetPlayerSpecialAction = new.bool(false),
    onSetPlayerFightingStyle = new.bool(false),
    onSetPlayerVelocity = new.bool(false),
    onSetVehicleVelocity = new.bool(false),
    onServerMessage = new.bool(false),
    onSetWorldTime = new.bool(false),
    onCreatePickup = new.bool(false),
    onMoveObject = new.bool(false),
    onEnableStuntBonus = new.bool(false),
    onTextDrawSetString = new.bool(false),
    onSetCheckpoint = new.bool(false),
    onCreateGangZone = new.bool(false),
    onPlayCrimeReport = new.bool(false),
    onGangZoneDestroy = new.bool(false),
    onGangZoneFlash = new.bool(false),
    onStopObject = new.bool(false),
    onSetVehicleNumberPlate = new.bool(false),
    onTogglePlayerSpectating = new.bool(false),
    onSpectatePlayer = new.bool(false),
    onSpectateVehicle = new.bool(false),
    onShowTextDraw = new.bool(false),
    onSetPlayerWantedLevel = new.bool(false),
    onTextDrawHide = new.bool(false),
    onRemoveMapIcon = new.bool(false),
    onSetWeaponAmmo = new.bool(false),
    onSetGravity = new.bool(false),
    onSetVehicleHealth = new.bool(false),
    onAttachTrailerToVehicle = new.bool(false),
    onDetachTrailerFromVehicle = new.bool(false),
    onSetWeather = new.bool(false),
    onSetPlayerSkin = new.bool(false),
    onSetInterior = new.bool(false),
    onSetCameraPosition = new.bool(false),
    onSetCameraLookAt = new.bool(false),
    onSetVehiclePosition = new.bool(false),
    onSetVehicleAngle = new.bool(false),
    onSetVehicleParams = new.bool(false),
    onSetCameraBehind = new.bool(false),
    onChatMessage = new.bool(false),
    onConnectionRejected = new.bool(false),
    onPlayerStreamOut = new.bool(false),
    onVehicleStreamIn = new.bool(false),
    onVehicleStreamOut = new.bool(false),
    onPlayerDeath = new.bool(false),
    onPlayerEnterVehicle = new.bool(false),
    onUpdateScoresAndPings = new.bool(false),
    onSetObjectMaterial = new.bool(false),
    onCreateActor = new.bool(false),
    onToggleSelectTextDraw = new.bool(false),
    onSetVehicleParamsEx = new.bool(false),
    onSetPlayerAttachedObject = new.bool(false),
    onClientCheck = new.bool(false),
    onDestroyActor = new.bool(false),
    onDestroyWeaponPickup = new.bool(false),
    onEditAttachedObject = new.bool(false),
    onToggleCameraTargetNotifying = new.bool(false),
    onEnterSelectObject = new.bool(false),
    onPlayerExitVehicle = new.bool(false),
    onVehicleTuningNotification = new.bool(false),
    onServerStatisticsResponse = new.bool(false),
    onEnterEditObject = new.bool(false),
    onVehicleDamageStatusUpdate = new.bool(false),
    onDisableVehicleCollisions = new.bool(false),
    onToggleWidescreen = new.bool(false),
    onSetVehicleTires = new.bool(false),
    onSetPlayerDrunkVisuals = new.bool(false),
    onSetPlayerDrunkHandling = new.bool(false),
    onApplyActorAnimation = new.bool(false),
    onClearActorAnimation = new.bool(false),
    onSetActorFacingAngle = new.bool(false),
    onSetActorPos = new.bool(false),
    onSetActorHealth = new.bool(false),
    onSetPlayerObjectNoCameraCol = new.bool(false),
    onSendRconCommand = new.bool(false),
    onSendStatsUpdate = new.bool(false),
    onSendPlayerSync = new.bool(false),
    onSendVehicleSync = new.bool(false),
    onSendPassengerSync = new.bool(false),
    onSendAimSync = new.bool(false),
    onSendUnoccupiedSync = new.bool(false),
    onSendTrailerSync = new.bool(false),
    onSendBulletSync = new.bool(false),
    onSendSpectatorSync = new.bool(false),
    onSendWeaponsUpdate = new.bool(false),
    onSendAuthenticationResponse = new.bool(false),
    onPlayerSync = new.bool(false),
    onVehicleSync = new.bool(false),
    onMarkersSync = new.bool(false),
    onAimSync = new.bool(false),
    onBulletSync = new.bool(false),
    onUnoccupiedSync = new.bool(false),
    onTrailerSync = new.bool(false),
    onPassengerSync = new.bool(false),
    onAuthenticationRequest = new.bool(false),
    onConnectionRequestAccepted = new.bool(false),
    onConnectionLost = new.bool(false),
    onConnectionBanned = new.bool(false),
    onConnectionAttemptFailed = new.bool(false),
    onConnectionNoFreeSlot = new.bool(false),
    onConnectionPasswordInvalid = new.bool(false),
    onConnectionClosed = new.bool(false)
}

local obxood = {
    obxod = new.bool(false),
    obxodd = false,
    obxodw = false,
    obxodn = false,
    obxoddd = new.bool(false),
    obxodnn = false,
    cobxod = new.bool(false),
}

local theme = new.int(ini.cfg.theme)
local style = new.int(ini.cfg.style)
local skycoordX = new.float(ini.mcheat.skycoordX)
local skycoordY = new.float(ini.mcheat.skycoordY)
local skycoordZ = new.float(ini.mcheat.skycoordZ)

local themesList, stylesList = {}, {}

local invis = {
    inv = new.bool(false),
    invad = new.bool(false),
    invv = new.bool(false),
    invx = new.float(0),
    invy = new.float(0),
    invz = new.float(0),
    exploit = new.bool(false),
    invi = new.bool(false),
    invc = new.bool(false),
    invcc = new.bool(false),
    slapx = new.float(0),
    slapy = new.float(0),
    slapz = new.float(0),
    invvv = new.bool(false),
    cloud = new.bool(false),
    otos = new.bool(false),
    vehInvisible = new.bool(false),
}

local objja = {
    [1271] = "ЯЩИК"
}

local objs = {
	[1575] = "DRUGS!",
	[1580] = "DRUGS!",
	[1576] = "DRUGS!",
	[1577] = "DRUGS!",
	[1578] = "DRUGS!",
	[1579] = "DRUGS!"
}

local grafobj = {
	[1529] = "ГРАФФИТИ",
	[18659] = "Grove Street",
	[18660] = "ГРАФФИТИ",
	[18661] = "Aztecas",
	[18662] = "Ballas",
	[18663] = "Rifa",
	[18665] = "Vagos",
	[18666] = "ГРАФФИТИ",
	[18667] = "Ballas",
	[1528] = "ГРАФФИТИ",
	[1531] = "aztecas",
	[18664] = "ГРАФФИТИ"
}

local Dobj = {
	[19315] = "DEER!"
}

local Gobj = {
	[348] = "desert_eagle",
	[356] = "M4",
	[355] = "АК-47",
	[358] = "Sniper",
	[357] = "cuntgun"
}

local kladobj = {
	[2680] = "KLAD!",
	[1271] = "KLAD!",
	[16317] = "KLAD!"
}

local rudaobj = {
	[854] = "RUDA!",
    [3930] = "Камень",
    [2936] = "Метал",
    [19941] = "Золото"

}

local lobj = {
	[865] = "LEN!"
    
}

local hobj = {
	[819] = "CUTTON!"
}


local teleportt = 1
local teleport = new.bool(false)
local pizda = new.bool(false)
local fastbegg = new.bool(false)
local rapidd = new.bool(false)
local weapon = new.bool(false)
local teleportt = new.bool(false)

local nop = {
ChatBubble = new.bool(false),
DisableCheckpoint = new.bool(false), -- 37,
SetRaceCheckpoint = new.bool(false), --  38,
DisableRaceCheckpoint = new.bool(false), --  39
SetCheckpoint = new.bool(false), --  107
ShowDialog = new.bool(false), --  61
AddGangZone = new.bool(false), --  108
GangZoneDestroy = new.bool(false), --  120
GangZoneFlash = new.bool(false), -- h 121
GangZoneStopFlash = new.bool(false), --  85
ShowGameText = new.bool(false), --  73
SetGravity = new.bool(false), --  146
ShowPlayerNameTag = new.bool(false), --  80
CreateObject = new.bool(false), -- - ID: 44
SetPlayerObjectMaterial = new.bool(false), -- - ID: 84
AttachObjectToPlayer = new.bool(false), --  - ID: 75
AttachCameraToObject = new.bool(false), --  - ID: 81
EditAttachedObject = new.bool(false), --  - ID: 116
EditObject = new.bool(false), --  - ID: 117
EnterEditObject = new.bool(false), --  - ID: 27
CancelEdit = new.bool(false), --  - ID: 28
SetObjectPos = new.bool(false), --  - ID: 45
SetObjectRotation = new.bool(false), --  - ID: 46
DestroyObject = new.bool(false), --  - ID: 47
MoveObject = new.bool(false), --  - ID: 99
StopObject = new.bool(false), --  - ID: 122
CreatePickup = new.bool(false), --  - ID: 95
DestroyPickup = new.bool(false),
SetPlayerFacingAngle = new.bool(false), --  - ID: 19
ServerJoin = new.bool(false), --  - ID: 137
ServerQuit = new.bool(false), --  - ID: 138
InitGame = new.bool(false), --  - ID: 139
UpdateScoresAndPings = new.bool(false), --  - ID: 155
ApplyPlayerAnimation = new.bool(false), --  - ID: 86
ClearPlayerAnimation = new.bool(false), --  - ID: 87
DeathBroadcast = new.bool(false), --  - ID: 166
SetPlayerName = new.bool(false), --  - ID: 11
SetPlayerPos = new.bool(false), --  - ID: 12
SetPlayerPosFindZ = new.bool(false), --  - ID: 13
SetPlayerSkillLevel = new.bool(false), --  - ID: 34
SetPlayerSkin = new.bool(false), --  - ID: 153
SetPlayerTime = new.bool(false), --  - ID: 29
SetWeather = new.bool(false), --  - ID: 152
SetWorldBounds = new.bool(false), --  - ID: 17
SetPlayerVelocity = new.bool(false), --  - ID: 90
TogglePlayerControllable = new.bool(false), --  - ID: 15
TogglePlayerSpectating = new.bool(false), --  - ID: 124
SetPlayerTeam = new.bool(false), --  - ID: 69
GivePlayerMoney = new.bool(false), --  - ID: 18
ResetPlayerMoney = new.bool(false), --  - ID: 20
ResetPlayerWeapons = new.bool(false), --  - ID: 21
GivePlayerWeapon = new.bool(false), --  - ID: 22
PlayAudioStream = new.bool(false), --  - ID: 41
StopAudioStream = new.bool(false), --  - ID: 42
RemoveBuilding = new.bool(false), --  - ID: 43
SetPlayerHealth = new.bool(false), --  - ID: 14
SetPlayerArmour = new.bool(false), --  - ID: 66
SetWeaponAmmo = new.bool(false), --  - ID: 145
SetArmedWeapon = new.bool(false), --  - ID: 67
SetPlayerColor = new.bool(false), --  - ID: 72
SetInterior = new.bool(false), --  - ID: 156
ForceClassSelection = new.bool(false), --  - ID: 74
SetPlayerWantedLevel = new.bool(false), --  - ID: 133
SetSpawnInfo = new.bool(false), --  - ID: 68
RequestClass = new.bool(false), --  - ID: 128
RequestSpawn = new.bool(false), --  - ID: 129
SpectatePlayer = new.bool(false), --  - ID: 126
SpectateVehicle = new.bool(false), --  - ID: 127
ToggleSelectTextDraw = new.bool(false), --  - ID: 83
TextDrawSetString = new.bool(false), --  - ID: 105
ShowTextDraw = new.bool(false), --  - ID: 134
HideTextDraw = new.bool(false), --  - ID: 135
PlayerEnterVehicle = new.bool(false), --  - ID: 26
PlayerExitVehicle = new.bool(false), --  - ID: 154
RemoveVehicleComponent = new.bool(false), --  - ID: 57
PutPlayerInVehicle = new.bool(false), --  - ID: 70
RemovePlayerFromVehicle = new.bool(false), --  - ID: 71
UpdateVehicleDamageStatus = new.bool(false), --  - ID: 106
SetVehicleNumberPlate = new.bool(false), --  - ID: 123
DisableVehicleCollisions = new.bool(false), --  - ID: 167
SetVehicleHealth = new.bool(false), --  - ID: 147
SetVehicleVelocity = new.bool(false), --  - ID: 91
SetVehiclePos = new.bool(false), --  - ID: 159
SetVehicleZAngle = new.bool(false), --  - ID: 160

--Incoming RPCs
EnterVehicle = new.bool(false), --  - ID: 26
ExitVehicle = new.bool(false), --  - ID: 154
VehicleDamaged = new.bool(false), --  - ID: 106
ScmEvent = new.bool(false), --  - ID: 96
VehicleDestroyed = new.bool(false), --  - ID: 136
SendSpawn = new.bool(false), --  - ID: 52
ChatMessage = new.bool(false), --  - ID: 101
InteriorChangeNotification = new.bool(false), -- - ID: 118
DeathNotification = new.bool(false), --  - ID: 53
SendCommand = new.bool(false), --  - ID: 50
ClickPlayer = new.bool(false), --  - ID: 23
DialogResponse = new.bool(false), --  - ID: 62
ClientCheckResponse = new.bool(false), --  - ID: 103
GiveTakeDamage = new.bool(false), --  - ID: 115
GiveActorDamage = new.bool(false), --  - ID: 177
MapMarker = new.bool(false), --  - ID: 119
RequestClass = new.bool(false), --  - ID: 128
RequestSpawn = new.bool(false), -- - ID: 129
MenuSelect = new.bool(false), --  - ID: 132
MenuQuit = new.bool(false), --  - ID: 140
SelectTextDraw = new.bool(false), --  - ID: 83
PickedUpPickup = new.bool(false), --  - ID: 131
SelectObject = new.bool(false), --  - ID: 27
EditAttachedObject = new.bool(false), --  - ID: 116
EditObject = new.bool(false), --  - ID: 117
UpdateScoresAndPings = new.bool(false), --  - ID: 155
ClientJoin = new.bool(false), --  - ID: 25
NPCJoin = new.bool(false), --  - ID: 54
CameraTarget = new.bool(false), --  - ID: 168

--Incoming Packets

ID_MARKERS_SYNC = new.bool(false),  -- ID: 208
NO_FREE_INCOMING_CONNECTION = new.bool(false),  -- ID:31
DISCONNECTION_NOTIFICATION  = new.bool(false), -- ID: 32
CONNECTION_LOST = new.bool(false),  -- ID: 33
CONNECTION_REQUEST_ACCEPTED = new.bool(false),  -- ID: 34 
UNKNOWN = new.bool(false),  -- ID: 35 
CONNECTION_BANNED = new.bool(false),  -- ID: 36 
INVALPASSWORD = new.bool(false), -- ID: 37

-- Outgoing Packet
CONNECTION_REQUEST = new.bool(false),  -- ID: 11
AUTH_KEY = new.bool(false),  -- ID: 12
MODIFIED_PACKET = new.bool(false),  -- ID: 38
VEHICLE_SYNC = new.bool(false),  -- ID: 200
RCON_COMMAND = new.bool(false),  -- ID: 201
UNKNOWNN = new.bool(false), -- ID: 202
AIM_SYNC = new.bool(false),  -- ID: 203
WEAPONS_UPDATE = new.bool(false),  -- ID: 204
STATS_UPDATE = new.bool(false),  -- ID: 205
BULLET_SYNC = new.bool(false),  -- ID: 206
ONFOOT_SYNC = new.bool(false),  -- ID: 207
UNOCCUPIED_SYNC = new.bool(false),  -- ID: 209
TRAILER_SYNC = new.bool(false),  -- ID: 210
PASSENGER_SYNC = new.bool(false),  -- ID: 211
SPECTATING_SYNC = new.bool(false)  -- ID: 212
}

local RPC = {
    SERVER = {
        [14] = 'SetPlayerHealth',
        [15] = 'TogglePlayerControlable',
        [86] = 'ApplyAnimation',
        [87] = 'ClearAnimation',
        [71] = 'RemovePlayerFromVehicle',
        [68] = 'SetSpawnInfo'
    },
    CLIENT = {
        [52] = 'Spawn',
        [128] = 'RequestClass',
        [129] = 'RequestSpawn'
    },
    PACKETS = {
        [207] = 'Player',
        [204] = 'Weapon Update'
    };
};
local font = renderCreateFont('Arial', 8, 4 + 8)
local renderWindow = imgui.new.bool(false)
local tab = 1

local settings = {
    sec = new.bool(false)
}
local button = {
    button1 = 225,
    button2 = 30
}
local button1 = {
    button1 = 250,
    button2 = 40
}



local LastActiveTime = {}
local LastActive = {}


function imgui.ToggleButton(str_id, bool)
    local rBool = false

    local p = imgui.GetCursorScreenPos()
    local draw_list = imgui.GetWindowDrawList()
    local height = 40
    local width = height * 1.55
    local radius = height * 0.50

    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        bool[0] = not bool[0]
        rBool = true
        LastActiveTime[tostring(str_id)] = imgui.GetTime()
        LastActive[tostring(str_id)] = true
    end

    local hovered = imgui.IsItemHovered()

    imgui.SameLine()
    imgui.SetCursorPosY(imgui.GetCursorPosY()+4)
    imgui.Text(str_id)

    local t = bool[0] and 1.0 or 0.0

    if LastActive[tostring(str_id)] then
        local time = imgui.GetTime() - LastActiveTime[tostring(str_id)]
        if time <= 0.13 then
            local t_anim = ImSaturate(time / 0.13)
            t = bool[0] and t_anim or 1.0 - t_anim
        else
            LastActive[tostring(str_id)] = false
        end
    end

    local col_bg = imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.Button])

    draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y + (height / 6)), imgui.ImVec2(p.x + width - 1.0, p.y + (height - (height / 6))), col_bg, 10.0)
    draw_list:AddCircleFilled(imgui.ImVec2(p.x + (bool[0] and radius + 1.5 or radius - 3) + t * (width - radius * 2.0), p.y + radius), radius - 6, imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.Text]))

    return rBool
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	for i, v in ipairs(themes) do table.insert(themesList, v.name) end
	for i, v in ipairs(styles) do table.insert(stylesList, v.name) end

	themes[theme[0]+1].func()
	styles[style[0]+1].func()
end)

function iniSave()
	inicfg.save(ini, iniFile)
end

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.50, 0.50))
        imgui.SetNextWindowSize(imgui.ImVec2(1400, 650), imgui.Cond.FirstUseEver)
        if imgui.Begin('Kori Cheat', renderWindow, imgui.WindowFlags.NoResize) then
            if imgui.Button(u8'Анти админ', imgui.ImVec2(button.button1, button.button2)) then
                tab = 1
            end
            imgui.SameLine()
            if imgui.Button(u8'Нопы', imgui.ImVec2(button.button1, button.button2)) then
                tab = 2
            end
            imgui.SameLine()
            if imgui.Button(u8'Вред.читы', imgui.ImVec2(button.button1, button.button2)) then
                tab = 3
            end
            imgui.SameLine()
            if imgui.Button(u8'Настройки', imgui.ImVec2(button.button1, button.button2)) then
                tab = 4
            end
            imgui.SameLine()
            if imgui.Button(u8('Флудер'), imgui.ImVec2(button.button1, button.button2)) then
                tab = 5
            end
            imgui.SameLine()
            if imgui.Button(u8('Рендер'), imgui.ImVec2(button.button1, button.button2)) then
                tab = 6
            end
            if tab == 1 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    if imgui.ToggleButton(u8'Антидмг', lol.antidmg) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF} теперь админы' .. (lol.antidmg[0] and ' не смогут вас посадить' or ' смогут вас посадить'), -1)
                        ini.antiadm.antidmg = lol.antidmg[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Фикс антидмг', lol.fix) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}фикс в' .. (lol.fix[0] and 'ключен' or 'ыключен'), -1)
                        ini.antiadm.fix = lol.fix[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Запрет изменение позиции', lol.setplayerpos) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}теперь сервер' .. (lol.setplayerpos[0] and ' не может редактировать ваши координаты' or ' может редактировать ваши координаты'), -1)
                        ini.antiadm.setplayerpos = lol.setplayerpos[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Запрет на фриз', lol.nott) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (lol.nott[0] and 'ключили запрет на фриз' or 'ыключили запрет на фриз'), -1)
                        ini.antiadm.nott = lol.nott[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Логирование текстдравов', lol.logTextdraws) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (lol.logTextdraws[0] and 'ключили логирование' or 'ыключили логирование'), -1)
                        ini.antiadm.logTextdraws = lol.logTextdraws[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Логирование пикапов', lol.PickedUpPickup) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (lol.PickedUpPickup[0] and 'ключили логирование' or 'ыключили логирование'), -1)
                        ini.antiadm.PickedUpPickup = lol.PickedUpPickup[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Отображать пикапов', lol.showpickup) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (lol.showpickup[0] and 'ключили отображение пикапов' or 'ыключили отображение пикапов'), -1)
                        ini.antiadm.showpickup = lol.showpickup[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Запрет на показ диалога', lol.nodialog) then
                        sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (lol.nodialog[0] and 'ключили запрет на показ диалога' or 'ыключили запрет на показ диалога'), -1)
                        ini.antiadm.nodialog = lol.nodialog[0]
                        iniSave()
                    end
                end
            elseif tab == 2 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                imgui.Text('                       ')
                imgui.SameLine()
                if imgui.Button(u8('RPC IN'), imgui.ImVec2(150, 30)) then
                    tab = 2
                end
                imgui.SameLine()
                if imgui.Button(u8('RPC OUT'), imgui.ImVec2(150, 30)) then
                    tab = 11
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET IN'), imgui.ImVec2(150, 30)) then
                    tab = 12
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET OUT'), imgui.ImVec2(150, 30)) then
                    tab = 13
                end
                imgui.SameLine()
                if imgui.Button(u8('SAMP.LUA'), imgui.ImVec2(150, 30)) then
                    tab = 17
                end
                imgui.Separator()
                imgui.Checkbox('ChatBubble', nop.ChatBubble)
                imgui.Checkbox('DisableCheckpoint', nop.DisableCheckpoint)
                imgui.Checkbox('SetRaceCheckpoint', nop.SetRaceCheckpoint)
                imgui.Checkbox('DisableRaceCheckpoint', nop.DisableRaceCheckpoint)
                imgui.Checkbox('SetCheckpoint', nop.SetCheckpoint)
                imgui.Checkbox('ShowDialog', nop.ShowDialog)
                imgui.Checkbox('AddGangZone', nop.AddGangZone)
                imgui.Checkbox('GangZoneDestroy', nop.GangZoneDestroy)
                imgui.Checkbox('GangZoneFlash', nop.GangZoneFlash)
                imgui.Checkbox('GangZoneStopFlash', nop.GangZoneStopFlash)
                imgui.Checkbox('ShowGameText', nop.ShowGameText)
                imgui.Checkbox('SetGravity', nop.SetGravity)
                imgui.Checkbox('ShowPlayerNameTag', nop.ShowPlayerNameTag)
                imgui.Checkbox('CreateObject', nop.CreateObject)
                imgui.Checkbox('SetPlayerObjectMaterial', nop.SetPlayerObjectMaterial)
                imgui.Checkbox('AttachObjectToPlayer', nop.AttachObjectToPlayer)
                imgui.Checkbox('AttachCameraToObject', nop.AttachCameraToObject)
                imgui.Checkbox('EditAttachedObject', nop.EditAttachedObject)
                imgui.Checkbox('EditObject', nop.EditObject)
                imgui.Checkbox('EnterEditObject', nop.EnterEditObject)
                imgui.Checkbox('CancelEdit', nop.CancelEdit)
                imgui.Checkbox('SetObjectPos', nop.SetObjectPos)
                imgui.Checkbox('SetObjectRotation', nop.SetObjectRotation)
                imgui.Checkbox('DestroyObject', nop.DestroyObject)
                imgui.Checkbox('MoveObject', nop.MoveObject)
                imgui.Checkbox('StopObject', nop.StopObject)
                imgui.Checkbox('CreatePickup', nop.CreatePickup)
                imgui.Checkbox('DestroyPickup', nop.DestroyPickup)
                imgui.Checkbox('SetPlayerFacingAngle', nop.SetPlayerFacingAngle)
                imgui.Checkbox('ServerJoin', nop.ServerJoin)
                imgui.Checkbox('ServerQuit', nop.ServerQuit)
                imgui.Checkbox('InitGame', nop.InitGame)
                imgui.Checkbox('UpdateScoresAndPings', nop.UpdateScoresAndPings)
                imgui.Checkbox('ApplyPlayerAnimation', nop.ApplyPlayerAnimation)
                imgui.Checkbox('ClearPlayerAnimation', nop.ClearPlayerAnimation)
                imgui.Checkbox('DeathBroadcast', nop.DeathBroadcast)
                imgui.Checkbox('SetPlayerName', nop.SetPlayerName)
                imgui.Checkbox('SetPlayerPos', nop.SetPlayerPos)
                imgui.Checkbox('SetPlayerPosFindZ', nop.SetPlayerPosFindZ)
                imgui.Checkbox('SetPlayerSkillLevel', nop.SetPlayerSkillLevel)
                imgui.Checkbox('SetPlayerSkin', nop.SetPlayerSkin)
                imgui.Checkbox('SetPlayerTime', nop.SetPlayerTime)
                imgui.Checkbox('SetWeather', nop.SetWeather)
                imgui.Checkbox('SetWorldBounds', nop.SetWorldBounds)
                imgui.Checkbox('SetPlayerVelocity', nop.SetPlayerVelocity)
                imgui.Checkbox('TogglePlayerControllable', nop.TogglePlayerControllable)
                imgui.Checkbox('TogglePlayerSpectating', nop.TogglePlayerSpectating)
                imgui.Checkbox('SetPlayerTeam', nop.SetPlayerTeam)
                imgui.Checkbox('GivePlayerMoney', nop.GivePlayerMoney)
                imgui.Checkbox('ResetPlayerMoney', nop.ResetPlayerMoney)
                imgui.Checkbox('GivePlayerWeapon', nop.GivePlayerWeapon)
                imgui.Checkbox('ResetPlayerMoney', nop.ResetPlayerWeapons)
                imgui.Checkbox('PlayAudioStream', nop.PlayAudioStream)
                imgui.Checkbox('StopAudioStream', nop.StopAudioStream)
                imgui.Checkbox('RemoveBuilding', nop.RemoveBuilding)
                imgui.Checkbox('SetPlayerHealth', nop.SetPlayerHealth)
                imgui.Checkbox('SetPlayerArmour', nop.SetPlayerArmour)
                imgui.Checkbox('SetArmedWeapon', nop.SetArmedWeapon)
                imgui.Checkbox('SetPlayerColor', nop.SetPlayerColor)
                imgui.Checkbox('SetInterior', nop.SetInterior)
                imgui.Checkbox('ForceClassSelection', nop.ForceClassSelection)
                imgui.Checkbox('SetPlayerWantedLevel', nop.SetPlayerWantedLevel)
                imgui.Checkbox('SetSpawnInfo', nop.SetSpawnInfo)
                imgui.Checkbox('RequestSpawn', nop.RequestSpawn)
                imgui.Checkbox('SpectateVehicle', nop.SpectateVehicle)
                imgui.Checkbox('ToggleSelectTextDraw', nop.ToggleSelectTextDraw)
                imgui.Checkbox('TextDrawSetString', nop.TextDrawSetString)
                imgui.Checkbox('ShowTextDraw', nop.ShowTextDraw)
                imgui.Checkbox('HideTextDraw', nop.HideTextDraw)
                imgui.Checkbox('PlayerEnterVehicle', nop.PlayerEnterVehicle)
                imgui.Checkbox('PlayerExitVehicle', nop.PlayerExitVehicle)
                imgui.Checkbox('RemoveVehicleComponent', nop.RemoveVehicleComponent)
                imgui.Checkbox('PutPlayerInVehicle', nop.PutPlayerInVehicle)
                imgui.Checkbox('RemovePlayerFromVehicle', nop.RemovePlayerFromVehicle)
                imgui.Checkbox('UpdateVehicleDamageStatus', nop.UpdateVehicleDamageStatus)
                imgui.Checkbox('SetVehicleNumberPlate', nop.SetVehicleNumberPlate)
                imgui.Checkbox('DisableVehicleCollisions', nop.DisableVehicleCollisions)
                imgui.Checkbox('SetVehicleHealth', nop.SetVehicleHealth)
                imgui.Checkbox('SetVehicleVelocity', nop.SetVehicleVelocity)
                imgui.Checkbox('SetVehiclePos', nop.SetVehiclePos)
                imgui.Checkbox('SetVehicleZAngle', nop.SetVehicleZAngle)
            end
            elseif tab == 17 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                imgui.Text('                       ')
                imgui.SameLine()
                if imgui.Button(u8('RPC IN'), imgui.ImVec2(150, 30)) then
                    tab = 2
                end
                imgui.SameLine()
                if imgui.Button(u8('RPC OUT'), imgui.ImVec2(150, 30)) then
                    tab = 11
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET IN'), imgui.ImVec2(150, 30)) then
                    tab = 12
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET OUT'), imgui.ImVec2(150, 30)) then
                    tab = 13
                end
                imgui.SameLine()
                if imgui.Button(u8('SAMP.LUA'), imgui.ImVec2(150, 30)) then
                    tab = 17
                end
                imgui.Separator()
                imgui.Checkbox(u8'onApplyPlayerAnimation', samplua.onApplyPlayerAnimation)
                imgui.Checkbox(u8'onAttachCameraToObject', samplua.onAttachCameraToObject)
                imgui.Checkbox(u8'onAttachObjectToPlayer', samplua.onAttachObjectToPlayer)
                imgui.Checkbox(u8'onCancelEdit', samplua.onCancelEdit)
                imgui.Checkbox(u8'onClearPlayerAnimation', samplua.onClearPlayerAnimation)
                imgui.Checkbox(u8'onCreate3DText', samplua.onCreate3DText)
                imgui.Checkbox(u8'onCreateExplosion', samplua.onCreateExplosion)
                imgui.Checkbox(u8'onCreateObject', samplua.onCreateObject)
                imgui.Checkbox(u8'onDestroyObject', samplua.onDestroyObject)
                imgui.Checkbox(u8'onCreatePickup', samplua.onCreatePickup)
                imgui.Checkbox(u8'onDestroyPickup', samplua.onDestroyPickup)
                imgui.Checkbox(u8'onDisableCheckpoint', samplua.onDisableCheckpoint)
                imgui.Checkbox(u8'onDisableRaceCheckpoint', samplua.onDisableRaceCheckpoint)
                imgui.Checkbox(u8'onDisplayGameText', samplua.onDisplayGameText)
                imgui.Checkbox(u8'onForceClassSelection', samplua.onForceClassSelection)
                imgui.Checkbox(u8'onGamemodeRestart', samplua.onGamemodeRestart)
                imgui.Checkbox(u8'onGangZoneStopFlash', samplua.onGangZoneStopFlash)
                imgui.Checkbox(u8'onGivePlayerMoney', samplua.onGivePlayerMoney)
                imgui.Checkbox(u8'onGivePlayerWeapon', samplua.onGivePlayerWeapon)
                imgui.Checkbox(u8'onHideMenu', samplua.onHideMenu)
                imgui.Checkbox(u8'onInitGame', samplua.onInitGame)
                imgui.Checkbox(u8'onInitMenu', samplua.onInitMenu)
                imgui.Checkbox(u8'onInterpolateCamera', samplua.onInterpolateCamera)
                imgui.Checkbox(u8'onLinkVehicleToInterior', samplua.onLinkVehicleToInterior)
                imgui.Checkbox(u8'onPlayAudioStream', samplua.onPlayAudioStream)
                imgui.Checkbox(u8'onPlaySound', samplua.onPlaySound)
                imgui.Checkbox(u8'onPlayerChatBubble', samplua.onPlayerChatBubble)
                imgui.Checkbox(u8'onPlayerDeathNotification', samplua.onPlayerDeathNotification)
                imgui.Checkbox(u8'onPlayerJoin', samplua.onPlayerJoin)
                imgui.Checkbox(u8'onPlayerQuit', samplua.onPlayerQuit)
                imgui.Checkbox(u8'onPlayerStreamIn', samplua.onPlayerStreamIn)
                imgui.Checkbox(u8'onPutPlayerInVehicle', samplua.onPutPlayerInVehicle)
                imgui.Checkbox(u8'onRemove3DTextLabel', samplua.onRemove3DTextLabel)
                imgui.Checkbox(u8'onRemoveBuilding', samplua.onRemoveBuilding)
                imgui.Checkbox(u8'onRemovePlayerFromVehicle', samplua.onRemovePlayerFromVehicle)
                imgui.Checkbox(u8'onRemoveVehicleComponent', samplua.onRemoveVehicleComponent)
                imgui.Checkbox(u8'onRequestClassResponse', samplua.onRequestClassResponse)
                imgui.Checkbox(u8'onRequestSpawnResponse', samplua.onRequestSpawnResponse)
                imgui.Checkbox(u8'onResetPlayerMoney', samplua.onResetPlayerMoney)
                imgui.Checkbox(u8'onResetPlayerWeapons', samplua.onResetPlayerWeapons)
                imgui.Checkbox(u8'onSendCameraTargetUpdate', samplua.onSendCameraTargetUpdate)
                imgui.Checkbox(u8'onSendChat', samplua.onSendChat)
                imgui.Checkbox(u8'onSendClickPlayer', samplua.onSendClickPlayer)
                imgui.Checkbox(u8'onSendClickTextDraw', samplua.onSendClickTextDraw)
                imgui.Checkbox(u8'onSendClientCheckResponse', samplua.onSendClientCheckResponse)
                imgui.Checkbox(u8'onSendClientJoin', samplua.onSendClientJoin)
                imgui.Checkbox(u8'onSendCommand', samplua.onSendCommand)
                imgui.Checkbox(u8'onSendDeathNotification', samplua.onSendDeathNotification)
                imgui.Checkbox(u8'onSendDialogResponse', samplua.onSendDialogResponse)
                imgui.Checkbox(u8'onSendEditAttachedObject', samplua.onSendEditAttachedObject)
                imgui.Checkbox(u8'onSendEditObject', samplua.onSendEditObject)
                imgui.Checkbox(u8'onSendEnterEditObject', samplua.onSendEnterEditObject)
                imgui.Checkbox(u8'onSendEnterVehicle', samplua.onSendEnterVehicle)
                imgui.Checkbox(u8'onSendExitVehicle', samplua.onSendExitVehicle)
                imgui.Checkbox(u8'onSendGiveActorDamage', samplua.onSendGiveActorDamage)
                imgui.Checkbox(u8'onSendGiveDamage', samplua.onSendGiveDamage)
                imgui.Checkbox(u8'onSendTakeDamage', samplua.onSendTakeDamage)
                imgui.Checkbox(u8'onSendInteriorChangeNotification', samplua.onSendInteriorChangeNotification)
                imgui.Checkbox(u8'onSendMapMarker', samplua.onSendMapMarker)
                imgui.Checkbox(u8'onSendMenuSelect', samplua.onSendMenuSelect)
                imgui.Checkbox(u8'onSendMoneyIncreaseNotification', samplua.onSendMoneyIncreaseNotification)
                imgui.Checkbox(u8'onSendNPCJoin', samplua.onSendNPCJoin)
                imgui.Checkbox(u8'onSendPickedUpPickup', samplua.onSendPickedUpPickup)
                imgui.Checkbox(u8'onSendPickedUpWeapon', samplua.onSendPickedUpWeapon)
                imgui.Checkbox(u8'onSendQuitMenu', samplua.onSendQuitMenu)
                imgui.Checkbox(u8'onSendRequestClass', samplua.onSendRequestClass)
                imgui.Checkbox(u8'onSendRequestSpawn', samplua.onSendRequestSpawn)
                imgui.Checkbox(u8'onSendServerStatisticsRequest', samplua.onSendServerStatisticsRequest)
                imgui.Checkbox(u8'onSendSpawn', samplua.onSendSpawn)
                imgui.Checkbox(u8'onSendUpdateScoresAndPings', samplua.onSendUpdateScoresAndPings)
                imgui.Checkbox(u8'onSendVehicleDamaged', samplua.onSendVehicleDamaged)
                imgui.Checkbox(u8'onSendVehicleDestroyed', samplua.onSendVehicleDestroyed)
                imgui.Checkbox(u8'onSendVehicleTuningNotification', samplua.onSendVehicleTuningNotification)
                imgui.Checkbox(u8'onSetMapIcon', samplua.onSetMapIcon)
                imgui.Checkbox(u8'onSetObjectPosition', samplua.onSetObjectPosition)
                imgui.Checkbox(u8'onSetObjectRotation', samplua.onSetObjectRotation)
                imgui.Checkbox(u8'onSetPlayerArmedWeapon', samplua.onSetPlayerArmedWeapon)
                imgui.Checkbox(u8'onSetPlayerArmour', samplua.onSetPlayerArmour)
                imgui.Checkbox(u8'onSetPlayerColor', samplua.onSetPlayerColor)
                imgui.Checkbox(u8'onSetPlayerDrunk', samplua.onSetPlayerDrunk)
                imgui.Checkbox(u8'onSetPlayerFacingAngle', samplua.onSetPlayerFacingAngle)
                imgui.Checkbox(u8'onSetPlayerFightingStyle', samplua.onSetPlayerFightingStyle)
                imgui.Checkbox(u8'onSetPlayerHealth', samplua.onSetPlayerHealth)
                imgui.Checkbox(u8'onSetPlayerName', samplua.onSetPlayerName)
                imgui.Checkbox(u8'onSetPlayerPos', samplua.onSetPlayerPos)
                imgui.Checkbox(u8'onSetPlayerPosFindZ', samplua.onSetPlayerPosFindZ)
                imgui.Checkbox(u8'onSetPlayerSkillLevel', samplua.onSetPlayerSkillLevel)
                imgui.Checkbox(u8'onSetPlayerSpecialAction', samplua.onSetPlayerSpecialAction)
                imgui.Checkbox(u8'onSetPlayerTeam', samplua.onSetPlayerTeam)
                imgui.Checkbox(u8'onSetPlayerTime', samplua.onSetPlayerTime)
                imgui.Checkbox(u8'onSetPlayerVelocity', samplua.onSetPlayerVelocity)
                imgui.Checkbox(u8'onSetRaceCheckpoint', samplua.onSetRaceCheckpoint)
                imgui.Checkbox(u8'onSetShopName', samplua.onSetShopName)
                imgui.Checkbox(u8'samplua.onSetSpawnInfo', samplua.onSetSpawnInfo)
                imgui.Checkbox(u8'samplua.onSetToggleClock', samplua.onSetToggleClock)
                imgui.Checkbox(u8'onSetWorldBounds', samplua.onSetWorldBounds)
                imgui.Checkbox(u8'onShowDialog', samplua.onShowDialog)
                imgui.Checkbox(u8'onShowMenu', samplua.onShowMenu)
                imgui.Checkbox(u8'onShowPlayerNameTag', samplua.onShowPlayerNameTag)
                imgui.Checkbox(u8'onStopAudioStream', samplua.onStopAudioStream)
                imgui.Checkbox(u8'onTogglePlayerControllable', samplua.onTogglePlayerControllable)
                imgui.Checkbox(u8'onUpdateGlobalTimer', samplua.onUpdateGlobalTimer)
            end
            elseif tab == 11 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('                       ')
                imgui.SameLine()
                if imgui.Button(u8('RPC IN'), imgui.ImVec2(150, 30)) then
                    tab = 2
                end
                imgui.SameLine()
                if imgui.Button(u8('RPC OUT'), imgui.ImVec2(150, 30)) then
                    tab = 11
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET IN'), imgui.ImVec2(150, 30)) then
                    tab = 12
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET OUT'), imgui.ImVec2(150, 30)) then
                    tab = 13
                end
                imgui.SameLine()
                if imgui.Button(u8('SAMP.LUA'), imgui.ImVec2(150, 30)) then
                    tab = 17
                end
                imgui.Separator()
                imgui.Checkbox('EnterVehicle', nop.EnterVehicle)
                imgui.Checkbox('ExitVehicle', nop.ExitVehicle)
                imgui.Checkbox('VehicleDamaged', nop.VehicleDamaged)
                imgui.Checkbox('ScmEvent', nop.ScmEvent)
                imgui.Checkbox('VehicleDestroyed', nop.VehicleDestroyed)
                imgui.Checkbox('Spawn', nop.SendSpawn)
                imgui.Checkbox('ChatMessage', nop.ChatMessage)
                imgui.Checkbox('InteriorChangeNotification', nop.InteriorChangeNotification)
                imgui.Checkbox('DeathNotification', nop.DeathNotification)
                imgui.Checkbox('SendCommand', nop.SendCommand)
                imgui.Checkbox('ClickPlayer', nop.ClickPlayer)
                imgui.Checkbox('DialogResponse', nop.DialogResponse)
                imgui.Checkbox('ClientCheckResponse', nop.ClientCheckResponse)
                imgui.Checkbox('GiveTakeDamage', nop.GiveTakeDamage)
                imgui.Checkbox('GiveActorDamage', nop.GiveActorDamage)
                imgui.Checkbox('MapMarker', nop.MapMarker)
                imgui.Checkbox('RequestClass', nop.RequestClass)
                imgui.Checkbox('RequestSpawn', nop.RequestSpawn)
                imgui.Checkbox('MenuSelect', nop.MenuSelect)
                imgui.Checkbox('MenuQuit', nop.MenuQuit)
                imgui.Checkbox('SelectTextDraw', nop.SelectTextDraw)
                imgui.Checkbox('PickedUpPickup', nop.PickedUpPickup)
                imgui.Checkbox('SelectObject', nop.SelectObject)
                imgui.Checkbox('EditAttachedObject', nop.EditAttachedObject)
                imgui.Checkbox('EditObject', nop.EditObject)
                imgui.Checkbox('UpdateScoresAndPings', nop.UpdateScoresAndPings)
                imgui.Checkbox('ClientJoin', nop.ClientJoin)
                imgui.Checkbox('NPCJoin', nop.NPCJoin)
                imgui.Checkbox('CameraTarget', nop.CameraTarget)
            end
            elseif tab == 12 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('                       ')
                imgui.SameLine()
                if imgui.Button(u8('RPC IN'), imgui.ImVec2(150, 30)) then
                    tab = 2
                end
                imgui.SameLine()
                if imgui.Button(u8('RPC OUT'), imgui.ImVec2(150, 30)) then
                    tab = 11
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET IN'), imgui.ImVec2(150, 30)) then
                    tab = 12
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET OUT'), imgui.ImVec2(150, 30)) then
                    tab = 13
                end
                imgui.SameLine()
                if imgui.Button(u8('SAMP.LUA'), imgui.ImVec2(150, 30)) then
                    tab = 17
                end
                imgui.Separator()
                imgui.Checkbox('ID_MARKERS_SYNC', nop.ID_MARKERS_SYNC)
                imgui.Checkbox('NO_FREE_INCOMING_CONNECTION', nop.NO_FREE_INCOMING_CONNECTION)
                imgui.Checkbox('DISCONNECTION_NOTIFICATION', nop.DISCONNECTION_NOTIFICATION)
                imgui.Checkbox('CONNECTION_LOST', nop.CONNECTION_LOST)
                imgui.Checkbox('CONNECTION_REQUEST_ACCEPTED', nop.CONNECTION_REQUEST_ACCEPTED)
                imgui.Checkbox('UNKNOWN', nop.UNKNOWN)
                imgui.Checkbox('CONNECTION_BANNED', nop.CONNECTION_BANNED)
                imgui.Checkbox('INVALPASSWORD', nop.INVALPASSWORD)
            end
            elseif tab == 13 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('                       ')
                imgui.SameLine()
                if imgui.Button(u8('RPC IN'), imgui.ImVec2(150, 30)) then
                    tab = 2
                end
                imgui.SameLine()
                if imgui.Button(u8('RPC OUT'), imgui.ImVec2(150, 30)) then
                    tab = 11
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET IN'), imgui.ImVec2(150, 30)) then
                    tab = 12
                end
                imgui.SameLine()
                if imgui.Button(u8('PACKET OUT'), imgui.ImVec2(150, 30)) then
                    tab = 13
                end
                imgui.SameLine()
                if imgui.Button(u8('SAMP.LUA'), imgui.ImVec2(150, 30)) then
                    tab = 17
                end
                imgui.Separator()
                imgui.Checkbox('CONNECTION_REQUEST', nop.CONNECTION_REQUEST)
                imgui.Checkbox('AUTH_KEY', nop.AUTH_KEY)
                imgui.Checkbox('MODIFIED_PACKET', nop.MODIFIED_PACKET)
                imgui.Checkbox('VEHICLE_SYNC', nop.VEHICLE_SYNC)
                imgui.Checkbox('RCON_COMMAND', nop.RCON_COMMAND)
                imgui.Checkbox('UNKNOWN##DEP', nop.UNKNOWNN)
                imgui.Checkbox('AIM_SYNC', nop.AIM_SYNC)
                imgui.Checkbox('WEAPONS_UPDATE', nop.WEAPONS_UPDATE)
                imgui.Checkbox('STATS_UPDATE', nop.STATS_UPDATE)
                imgui.Checkbox('BULLET_SYNC', nop.BULLET_SYNC)
                imgui.Checkbox('ONFOOT_SYNC', nop.ONFOOT_SYNC)
                imgui.Checkbox('UNOCCUPIED_SYNC', nop.UNOCCUPIED_SYNC)
                imgui.Checkbox('TRAILER_SYNC', nop.TRAILER_SYNC)
                imgui.Checkbox('PASSENGER_SYNC', nop.PASSENGER_SYNC)
                imgui.Checkbox('SPECTATING_SYNC', nop.SPECTATING_SYNC)
            end
                elseif tab == 4 then
                    imgui.SetCursorPos(imgui.ImVec2(5, 70))
                    if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.ToggleButton(u8'деморган в минутах', settings.sec)
                    if imgui.Button(u8'Очистить чат') then
                        for i = 1, 15 do 
                            sampAddChatMessage('', -1) 
                        end
                    end
                    if imgui.Combo(u8'Тема', theme, new['const char*'][#themesList](themesList), #themesList) then 
                        themes[theme[0]+1].func() 
                        iniSave() 
                    end
                    if imgui.Combo(u8'Стиль', style, new['const char*'][#stylesList](stylesList), #stylesList) then 
                        styles[style[0]+1].func() 
                        iniSave() 
                    end
                    if imgui.Button(u8'удалить скрипт') then
                        deletee = not deletee
                    end
                        if deletee then
                        imgui.Text(u8'ты уверен?')
                        if imgui.Button(u8'да') then
                        os.remove(thisScript().path)
					    thisScript():unload()
                        end
                        imgui.SameLine()
                        if imgui.Button(u8'нет') then
                        deletee = not deletee
                        end
                    end

                    if imgui.Button(u8'выгрузить скрипт') then
					    thisScript():unload()
                    end
                    if imgui.Button(u8'перезагрузить скрипт') then
					    thisScript():reload()
                    end
                    imgui.Text(u8'Автор: @Langerv, тгк: @tglangera')
                    imgui.Text(u8'p.s если вы не знаете как использовать нопы, гуглите их значение или используйте обходы/анти админ')
                end
                elseif tab == 3 then
                    imgui.SetCursorPos(imgui.ImVec2(5, 70))
                    if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('         ')
                    imgui.SameLine()
                    if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 3
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 7
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 8
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 9
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 16
                    end
                    if imgui.Button(u8'Быстрый бег') then
                        fastbegg[0] = not fastbegg[0]
                    end
                    imgui.SameLine()
                    if imgui.Button(u8'Рапид') then
                        rapidd[0] = not rapidd[0]
                    end
                    if imgui.ToggleButton(u8'Поле зрение', lol.rglaz) then
                        ini.mcheat.rglaz = lol.rglaz[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.SliderFloat(u8'градусов', lol.rglazz, 50, 130) then
                        ini.mcheat.rglazz = lol.rglazz[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Антистан                                                             ', lol.antistun) then
                        if lol.antistun[0] then
                        antistun()
                        ini.mcheat.antistun = lol.antistun[0]
                        iniSave()
                        end
                    end
                    imgui.SameLine() 
                    if imgui.ToggleButton(u8'Беск. бег', lol.infrun) then
                        ini.mcheat.infrun = lol.infrun[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Noreload                                                              ', lol.noreload) then
                        ini.antiadm.noreload = lol.noreload[0]
                        iniSave()
                    end
                    imgui.SameLine() 
                    if imgui.ToggleButton(u8'Анти падение', lol.nofall) then
                        if lol.nofall[0] then
                        nofal()
                        ini.mcheat.nofall = lol.nofall[0]
                        iniSave()
                        end
                    end
                    if imgui.ToggleButton(u8'Гм персонаж                                                       ', lol.gmp) then
                        ini.mcheat.gmp = lol.gmp[0]
                        iniSave()
                    end
                    imgui.SameLine() 
                    if imgui.ToggleButton(u8'Выдать себе 1к хп                                                        ', lol.gethp) then
                        ini.mcheat.gethp = lol.gethp[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'AntiDriveBy                                                          ', lol.andb) then
                        ini.mcheat.andb = lol.andb[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Беск. пт                                                            ', lol.infpt) then
                        ini.mcheat.infpt = lol.infpt[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8"Блокировка анимации наркотиков                     ", lol.blockdruganim) then
                        ini.mcheat.blockdruganim = lol.blockdruganim[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Удалить шлагбаумы', lol.ash) then
                        ini.mcheat.ash = lol.ash[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Фейк скиллы                                                        ', lol.setskill) then
                    ini.mcheat.setskill = lol.setskill[0]
                    iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Пизда автомобилям', lol.pcar) then
                        ini.mcheat.pcar = lol.pcar[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Антистан2                                                             ', lol.antistuun) then
                        ini.mcheat.antistuun = lol.antistuun[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Анти капт', lol.anticapt) then
                        ini.mcheat.anticapt = lol.anticapt[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'SurfOnVehicle                                                        ', lol.surf) then
                        ini.mcheat.surf = lol.surf[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'antidrop object', lol.antidrop) then
                        ini.mcheat.antidrop = lol.antidrop[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'антистан3                                                              ', lol.antistuuun) then
                        ini.mcheat.antistuuun = lol.antistuuun[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'анти застревание в игрока', lol.antiplayer) then
                        ini.mcheat.antiplayer = lol.antiplayer[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'анти маска                                                            ', lol.antimask) then
                        ini.mcheat.antimask = lol.antimask[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'макс урон с дробовика', lol.maxdamage) then
                        ini.mcheat.maxdamage = lol.maxdamage[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'двойной урон                                                        ', lol.doubleDamage) then
                        ini.mcheat.doubleDamage = lol.doubleDamage[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'тройной урон', lol.tripleDamage) then
                        ini.mcheat.tripleDamage = lol.tripleDamage[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'скип диалога зз                                                     ', lol.skipzz) then
                        ini.mcheat.skipzz = lol.skipzz[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Убийство бота 1 удара', lol.killbots) then
                        ini.mcheat.killbots = lol.killbots[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'выбрать урон(/damage урон, не работает на арз)', lol.bigdamage) then
                        ini.mcheat.bigdamage = lol.bigdamage[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'wallhack', lol.wallhack) then
                        sampAddChatMessage('функция временно не работает, увы', -1)
                    end
                    imgui.ToggleButton(u8'дамагер                                                                 ', lol.damager)
                    imgui.SameLine()
                    imgui.ToggleButton(u8'дамагер с большим уроном', lol.damagerr)
                    imgui.ToggleButton(u8'destroy car', lol.destroy)
                    if imgui.Button(u8'настройки пизда автомобилям') then
                        pizda[0] = not pizda[0]
                    end
                    if imgui.Button(u8'Умереть') then
                        setCharHealth(PLAYER_PED, 0)
                    end
                    if imgui.Button(u8'walk on sky') then
                        skywalk = not skywalk
                    end
                    if skywalk then
                    imgui.Text(u8'change object')
                    imgui.SliderFloat('X##xa', skycoordX, 0, 10)
                    imgui.SliderFloat('Y##xa', skycoordY, 0, 10)
                    imgui.SliderFloat('Z##xa', skycoordZ, 0, 10)
                    end
                    imgui.Text('')
                    if imgui.Button(u8'Мини телепорт') then
                        local X, Y, Z = getCharCoordinates(PLAYER_PED)
                        setCharCoordinates(PLAYER_PED, X+invis.slapx[0], Y+invis.slapy[0], Z+invis.slapz[0])
                    end
                    imgui.SameLine()
                    imgui.Text('')
                    imgui.SameLine()
                    if imgui.Button(u8'телепорты') then
                        teleportt[0] = not teleportt[0]
                        renderWindow[0] = not renderWindow[0]
                    end
                    imgui.SliderFloat(u8'X##dep', invis.slapx, -100, 100)
                    imgui.Text('')
                    imgui.SliderFloat(u8'Y##dep', invis.slapy, -100, 100)
                    imgui.Text('')
                    imgui.SliderFloat(u8'Z##dep', invis.slapz, -100, 100)
                end
                elseif tab == 7 then
                    imgui.SetCursorPos(imgui.ImVec2(5, 70))
                    if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                        imgui.Text('         ')
                    imgui.SameLine()
                    if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 3
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 7
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 8
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 9
                    end
                    imgui.SameLine()
                    if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                        tab = 16
                    end
                    if imgui.ToggleButton(u8'Карскилл не тратиться  ', lol.anticarskill) then
                        ini.mcheat.anticarskill = lol.anticarskill[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Antieject', lol.antieject) then
                        ini.mcheat.antieject = lol.antieject[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'GM авто                          ', lol.godcar) then
                        ini.mcheat.godcar = lol.godcar[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'GM колеса', lol.gmkolesa) then
                        ini.mcheat.gmkolesa = lol.gmkolesa[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Бесконечный бензин     ', lol.infinityfuel) then
                        ini.mcheat.infinityfuel = lol.infinityfuel[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Моментальная раскрутка лопостей', lol.heliblades) then
                        ini.mcheat.heliblades = lol.heliblades[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Удалить шлагбаумы       ', lol.ash) then
                        ini.mcheat.ash = lol.ash[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Езда без карскилла', lol.antiogranichitel) then
                        ini.mcheat.antiogranichitel = lol.antiogranichitel[0]
                        iniSave()
                    end
                    if imgui.ToggleButton(u8'Nobike                            ', lol.nobike) then
                        ini.mcheat.nobike = lol.nobike[0]
                        iniSave()
                    end
                    imgui.SameLine()
                    if imgui.ToggleButton(u8'Jump car', lol.jumpcar) then
                        ini.mcheat.jumpcar = lol.jumpcar[0]
                        iniSave()
                    end
                    imgui.ToggleButton(u8'100k', lol.hp)
                    imgui.SameLine()
                    imgui.ToggleButton(u8'CarLagger', lol.lagger)
                    if imgui.ToggleButton(u8'Speedhack', lol.speedhack) then
                        ini.mcheat.speedhack = lol.speedhack[0]
                        iniSave()
                    end
                    if lol.speedhack[0] then
                        imgui.SameLine()
                        if imgui.SliderFloat(u8'Ускорение', lol.speed, 0, 5) then
                            ini.mcheat.speed = lol.speed[0]
                            iniSave()
                        end
                    end
                    if imgui.ToggleButton(u8'Сесть в любое авто', lol.carsit) then
                        ini.mcheat.carsit = lol.carsit[0]
                        iniSave()
                    end
                    if lol.carsit[0] then
                        if imgui.ToggleButton(u8'обход через пассажирку', lol.carpas) then
                            ini.mcheat.carpas = lol.carpas[0]
                            iniSave()
                        end
                        if imgui.SliderFloat(u8'задержка для езды', lol.cardelay, 0, 500) then
                            ini.mcheat.cardelay = lol.cardelay[0]
                            iniSave()
                        end
                    end
                    if imgui.Button(u8'Перевернуться') then
                        if isCharInAnyCar(PLAYER_PED) then
                        local veh = storeCarCharIsInNoSave(PLAYER_PED)
                        local x, y, z = getCarCoordinates(veh)
                        setCarCoordinates(veh, x, y, z)
                        end
                    end
                end
            elseif tab == 8 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('         ')
                imgui.SameLine()
                if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 3
                end
                imgui.SameLine()
                if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 7
                end
                imgui.SameLine()
                if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 8
                end
                imgui.SameLine()
                if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 9
                end
                imgui.SameLine()
                if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 16
                end
                if imgui.ToggleButton(u8'инвиз по изменение координат (ONFOOT1) ', invis.inv) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.inv[0] and 'ключили инвиз (ONFOOT), метод surfingOffsets' or 'ыключили инвиз (ONFOOT)'), -1)
                end
                if imgui.ToggleButton(u8'инвиз по изменение координат (ONFOOT2) ', invis.invv) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.invv[0] and 'ключили инвиз (ONFOOT), метод position ' or 'ыключили инвиз (ONFOOT)'), -1)
                end
                if imgui.ToggleButton(u8'инвиз по изменение координат (VEHICLE)', invis.invcc) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.invcc[0] and 'ключили инвиз (VEHICLE), метод position' or 'ыключили инвиз (VEHICLE)'), -1)
                end
                if imgui.ToggleButton(u8'инвиз по изменение координат (ONFOOT3) ', invis.invvv) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.invvv[0] and 'ключили инвиз, метод surfingOffsets' or 'ыключили инвиз'), -1)
                end
                if imgui.ToggleButton(u8'Desync-Invis (VEHICLE)', invis.vehInvisible) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.vehInvisible[0] and 'ключили инвиз (VEHICLE)‚ метод  surfingOffsets' or 'ыключили инвиз'), -1)
                end
                imgui.SliderFloat(u8'X', invis.invx, -100, 100)
                imgui.Text('')
                imgui.SliderFloat(u8'Y', invis.invy, -100, 100)
                imgui.Text('')
                imgui.SliderFloat(u8'Z', invis.invz, -100, 100)
                if imgui.ToggleButton(u8'эксплойт', invis.exploit) then
                    if invis.exploit[0] then
                        sampAddChatMessage("{696969}[Kori Cheat] {FFFFFF}Эксплоит включен, перезайдите на сервер!",-1)
                    else
                        lua_thread.create(function()
                        wait(1500)
                        sampSendSpawn()
                        sampAddChatMessage("{696969}[Kori Cheat] {FFFFFF}Эксплоит выключен",-1)
                        end)
                    end
                end
                if imgui.ToggleButton(u8'телепорт до координат 0 0 0 (визуально вы будете стоять на том месте, где вы стояли до)', invis.invad) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы ' .. (invis.invad[0] and 'теперь вы находитесь на координатах 0 0 0' or 'теперь вы не находитесь на координатах 0 0 0'), -1)
                end
                if imgui.ToggleButton(u8'спектаторка', invis.otos) then
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF}вы в' .. (invis.otos[0] and 'ключили спектаторку' or 'ыключили спектаторку'), -1)
                end
                if imgui.ToggleButton(u8'фулл инвиз', invis.invi) then
                    sampAddChatMessage('{696969}[Kori Cheat] : {FFFFFF}вы в' .. (invis.invi[0] and 'ключили фулл инвиз' or 'ыключили фулл инвиз'), -1)
                end
                if imgui.ToggleButton(u8'инвиз', invis.cloud) then
                    sampAddChatMessage('{696969}[Kori Cheat] : {FFFFFF}вы в' .. (invis.cloud[0] and 'ключили инвиз' or 'ыключили инвиз'), -1)
                end
                if imgui.ToggleButton(u8'update фулл инвиз', lol.volent) then
                    sampAddChatMessage('{696969}[Kori Cheat] : {FFFFFF}вы в' .. (lol.volent[0] and 'ключили фулл инвиз' or 'ыключили фулл инвиз'), -1)
                end
                imgui.SameLine()
                if imgui.ToggleButton(u8'movespeed', lol.move) then
                    sampAddChatMessage('{696969}[Kori Cheat] : {FFFFFF}вы в' .. (lol.move[0] and 'ключили movespeed (пикапы будет брать сложнее)' or 'ыключили movespeed'), -1)
                end
            end
            elseif tab == 9 then
                imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                    imgui.Text('         ')
                imgui.SameLine()
                if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 3
                end
                imgui.SameLine()
                if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 7
                end
                imgui.SameLine()
                if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 8
                end
                imgui.SameLine()
                if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 9
                end
                imgui.SameLine()
                if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                    tab = 16
                end
                if imgui.Button(u8'Сменить интерьер') then
                    sampSendInteriorChange(lol.interr[0])
                end
                imgui.SameLine()
                imgui.InputInt(u8'Ид интерьера', lol.interr)
                if imgui.Button(u8'Кликнуть на текстдрав') then
                    sampSendClickTextdraw(lol.textdraw[0])
                end
                imgui.SameLine()
                imgui.InputInt(u8'Ид текстдрава', lol.textdraw)
                if imgui.Button(u8'Поднять пикап') then
                    sampSendPickedUpPickup(lol.pickup[0])
                end
                imgui.SameLine()
                imgui.InputInt(u8'ид пикапа', lol.pickup)
                if imgui.Button(u8'RequestClass') then
                    sampRequestClass(lol.RC[0])
                end
                imgui.SameLine()
                imgui.InputInt(u8'Request', lol.RC)

                if imgui.ToggleButton(u8'флуд альтом', checkboxx) then
                    floodalt = not floodalt
                end

                if imgui.Button(u8'фикс бага с изменением интерьера') then
                    setInteriorVisible(0)
                end
                if imgui.Button(u8'перебор Textdraw', imgui.ImVec2(200, 30)) then
                    tab = 10
                end
                imgui.Text('')
                if imgui.Button(u8'перебор Pickup', imgui.ImVec2(200, 30)) then
                    tab = 14
                end
                imgui.Text('')
                if imgui.Button(u8'перебор RequestClass', imgui.ImVec2(200, 30)) then
                    tab = 15
                end
                imgui.Text('')
                imgui.Separator()
                imgui.ToggleButton(u8'обход чтобы сесть в авто (онли нубо рп)', obxood.cobxod)
                if imgui.Button(u8'обход античита через Weapon-Config', obxood.obxodw) then
                    if obxood.obxodd then
                        obxood.obxodd = false
                    end
                end
                if imgui.Button(u8'обход античита через NPC', obxood.obxodn) then
                    reco()
                end
                if imgui.Button(u8'обход античита через death', obxood.obxodd) then
                    if obxood.obxodw then
                        obxood.obxodw = false
                    end
                    ENABLE_BYPASS(obxood.obxodd)
                end
                if imgui.Button(u8'спавн') then
                    sampSendSpawn()
                end
            end
        elseif tab == 16 then
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
                if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
            imgui.Text('         ')
            imgui.SameLine()
            if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 3
            end
            imgui.SameLine()
            if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 7
            end
            imgui.SameLine()
            if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 8
            end
            imgui.SameLine()
            if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 9
            end
            imgui.SameLine()
            if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 16
            end
            imgui.ToggleButton(u8'Включить', lol.clientconnect)
            imgui.InputText(u8'version', lol.version, ffi.sizeof(lol.version))
            imgui.InputText(u8'mod', lol.mod, ffi.sizeof(lol.mod))
            imgui.InputText(u8'nickname', lol.nickname, ffi.sizeof(lol.nickname))
            imgui.InputText(u8'challengeResponse', lol.challengeResponse, ffi.sizeof(lol.challengeResponse))
            imgui.InputText(u8'joinAuthKey', lol.joinAuthKey, ffi.sizeof(lol.joinAuthKey))
            imgui.InputText(u8'clientVer', lol.clientVer, ffi.sizeof(lol.clientVer))
            imgui.InputText(u8'challengeResponse2', lol.challengeResponse2, ffi.sizeof(lol.challengeResponse2))
        end
        elseif tab == 10 then
            imgui.Text('         ')
            imgui.SameLine()
            if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 3
            end
            imgui.SameLine()
            if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 7
            end
            imgui.SameLine()
            if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 8
            end
            imgui.SameLine()
            if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 9
            end
            imgui.SameLine()
            if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 16
            end
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
            if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                imgui.PushItemWidth(200)
                imgui.InputInt(u8'Задержка##brute', bruteDelay, 0, 0)
                imgui.PopItemWidth()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'От##brute', bruteMin, 0, 0)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'До##brute', bruteMax, 0, 0, bruteEnabled)
                imgui.PopItemWidth()
               if imgui.Button((bruteEnabled and u8'Выключить' or u8'Включить') .. u8' перебор', imgui.ImVec2(-0.1, 20)) then
                    bruteEnabled = not bruteEnabled
                    brutePaused = false
                    if bruteEnabled then
                        lua_thread.create(brute)
                    end   
                end
                if bruteEnabled then
                    if imgui.Button(brutePaused and u8'Продолжить' or u8'Пауза', imgui.ImVec2(-0.1, 20)) then
                        brutePaused = not brutePaused
                    end
                end
                imgui.Text(u8'Текущий ID: ' .. bruteCurrent)
            end
        elseif tab == 14 then
            imgui.Text('         ')
            imgui.SameLine()
            if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 3
            end
            imgui.SameLine()
            if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 7
            end
            imgui.SameLine()
            if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 8
            end
            imgui.SameLine()
            if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 9
            end
            imgui.SameLine()
            if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 16
            end
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
            if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                imgui.PushItemWidth(200)
                imgui.InputInt(u8'Задержка##brute', bruteDelay, 0, 0)
                imgui.PopItemWidth()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'От##brute', bruteMin, 0, 0)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'До##brute', bruteMax, 0, 0, bruteEnabled)
                imgui.PopItemWidth()
               if imgui.Button((bruteEnabled and u8'Выключить' or u8'Включить') .. u8' перебор', imgui.ImVec2(-0.1, 20)) then
                    bruteEnabled = not bruteEnabled
                    brutePaused = false
                    if bruteEnabled then
                        lua_thread.create(brutee)
                    end   
                end
                if bruteEnabled then
                    if imgui.Button(brutePaused and u8'Продолжить' or u8'Пауза', imgui.ImVec2(-0.1, 20)) then
                        brutePaused = not brutePaused
                    end
                end
                imgui.Text(u8'Текущий ID: ' .. bruteCurrent)
            end
        elseif tab == 15 then
            imgui.Text('         ')
            imgui.SameLine()
            if imgui.Button(u8('Onfoot'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 3
            end
            imgui.SameLine()
            if imgui.Button(u8('Vehicle'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 7
            end
            imgui.SameLine()
            if imgui.Button(u8('Инвиз'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 8
            end
            imgui.SameLine()
            if imgui.Button(u8('Обходы / Отправка'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 9
            end
            imgui.SameLine()
            if imgui.Button(u8('Эмуляция'), imgui.ImVec2(button1.button1, button1.button2)) then
                tab = 16
            end
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
            if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
                imgui.PushItemWidth(200)
                imgui.InputInt(u8'Задержка##brute', bruteDelay, 0, 0)
                imgui.PopItemWidth()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'От##brute', bruteMin, 0, 0)
                imgui.PopItemWidth()
                imgui.SameLine()
                imgui.PushItemWidth(50)
                imgui.InputInt(u8'До##brute', bruteMax, 0, 0, bruteEnabled)
                imgui.PopItemWidth()
               if imgui.Button((bruteEnabled and u8'Выключить' or u8'Включить') .. u8' перебор', imgui.ImVec2(-0.1, 20)) then
                    bruteEnabled = not bruteEnabled
                    brutePaused = false
                    if bruteEnabled then
                        lua_thread.create(bruteee)
                    end   
                end
                if bruteEnabled then
                    if imgui.Button(brutePaused and u8'Продолжить' or u8'Пауза', imgui.ImVec2(-0.1, 20)) then
                        brutePaused = not brutePaused
                    end
                end
                imgui.Text(u8'Текущий ID: ' .. bruteCurrent)
            end
        elseif tab == 5 then
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
            if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
            imgui.ToggleButton(u8'включить флуд (1)', lol.flood)
            imgui.InputText(u8'Текст (1)', lol.text, ffi.sizeof(lol.text))
            if imgui.InputInt(u8'Задержка (1)', lol.delay1, ffi.sizeof(lol.delay1)) then
                ini.flooder.delay1 = lol.delay1[0]
                iniSave()
            end
            imgui.Text('')
            imgui.ToggleButton(u8'включить флуд (2)', lol.floodd)
            if imgui.InputText(u8'Текст (2)', lol.textt, ffi.sizeof(lol.textt)) then
                ini.flooder.textt = lol.textt[0]
            end
            if imgui.InputInt(u8'Задержка (2)', lol.delayy, ffi.sizeof(lol.delayy)) then
                ini.flooder.delayy = lol.delayy[0]
                iniSave()
            end
            imgui.Text('')
            imgui.ToggleButton(u8'включить флуд (3)', lol.flooddd)
            if imgui.InputText(u8'Текст (3)', lol.texttt, ffi.sizeof(lol.texttt)) then
                ini.flooder.texttt = lol.texttt[0]
            end
            if imgui.InputInt(u8'Задержка (3)', lol.delayyy, ffi.sizeof(lol.delayyy)) then
                ini.flooder.delayyy = lol.delayyy[0]
                iniSave()
            end
            end
        elseif tab == 6 then
            imgui.SetCursorPos(imgui.ImVec2(5, 70))
            if imgui.BeginChild('Name##', imgui.ImVec2(1360, 580), true) then
            if imgui.ToggleButton(u8'Рендер на наркотики', lol.nark) then
                ini.render.nark = lol.nark[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на оленей', lol.olen) then
                ini.render.olen = lol.olen[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на оружие', lol.gun) then
                ini.render.gun = lol.gun[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на клады', lol.klad) then
                ini.render.klad = lol.klad[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на руду', lol.ruda) then
                ini.render.ruda = lol.ruda[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на лен', lol.len) then
                ini.render.len = lol.len[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на хлопок', lol.hlopok) then
                ini.render.hlopok = lol.hlopok[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на граффити', lol.graf) then
                ini.render.graf = lol.graf[0]
                iniSave()
            end
            if imgui.ToggleButton(u8'Рендер на ящики из кб', lol.xye) then
                ini.render.xye = lol.xye[0]
                iniSave()
            end
                end
            end
        end    
    imgui.End()
end)

function brute()
    if bruteMin[0] > bruteMax[0] then
        local t = bruteMin[0]
        bruteMin[0] = bruteMax[0]
        bruteMax[0] = t
    end
    for i = bruteMin[0], bruteMax[0] do
        while brutePaused do
            wait(0)
        end
        if not bruteEnabled then
            break
        end
        bruteCurrent = i
        sampSendClickTextdraw(bruteCurrent)
        wait(bruteDelay[0])
    end
    bruteEnabled = false
end

function brutee()
    if bruteMin[0] > bruteMax[0] then
        local t = bruteMin[0]
        bruteMin[0] = bruteMax[0]
        bruteMax[0] = t
    end
    for i = bruteMin[0], bruteMax[0] do
        while brutePaused do
            wait(0)
        end
        if not bruteEnabled then
            break
        end
        bruteCurrent = i
        sampRequestClass(bruteCurrent)
        wait(bruteDelay[0])
    end
    bruteEnabled = false
end



function bruteee()
    if bruteMin[0] > bruteMax[0] then
        local t = bruteMin[0]
        bruteMin[0] = bruteMax[0]
        bruteMax[0] = t
    end
    for i = bruteMin[0], bruteMax[0] do
        while brutePaused do
            wait(0)
        end
        if not bruteEnabled then
            break
        end
        bruteCurrent = i
            sampRequestClass(bruteCurrent)
        wait(bruteDelay[0])
    end
    bruteEnabled = false
end

local newFrame = imgui.OnFrame(
    function() return teleportt[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.50, 0.50))
        imgui.SetNextWindowSize(imgui.ImVec2(1050, 500), imgui.Cond.FirstUseEver)
        if imgui.Begin('Teleport', teleportt) then
            imgui.Text('                           ')
            imgui.SameLine()
            if imgui.Button(u8'Квесты', imgui.ImVec2(180, 60)) then
                teleport = 1
            end
            imgui.SameLine()
            if imgui.Button(u8'Военка', imgui.ImVec2(180, 60)) then
                teleport = 7
            end
            imgui.SameLine()
            if imgui.Button(u8'Притоны', imgui.ImVec2(180, 60)) then
                teleport = 8
            end
            imgui.SameLine()
            if imgui.Button(u8'Мафия', imgui.ImVec2(180, 60)) then
                teleport = 9
            end
            if imgui.Button(u8'Банды', imgui.ImVec2(168, 110)) then
                teleport = 2
            end
            if imgui.Button(u8'Разные места', imgui.ImVec2(168, 110)) then
                teleport = 3
            end
            if imgui.Button(u8'Вернуться назад', imgui.ImVec2(168, 110)) then
                teleportt[0] = not teleportt[0]
                renderWindow[0] = not renderWindow[0]
            end
        if teleport == 1 then
            imgui.SetCursorPos(imgui.ImVec2(175, 100))
            if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'1 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 4
                end
                imgui.SameLine()
                if imgui.Button(u8'2 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 5
                end
                imgui.SameLine()
                if imgui.Button(u8'3 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 6
                end
            end
        elseif teleport == 2 then
            imgui.SetCursorPos(imgui.ImVec2(175, 100))
            if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                    if imgui.Button('Groove street', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2449.7219238281, -1708.0480957031, 13.697713851929)
                    end
                    imgui.SameLine()
                    if imgui.Button('Ballas', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 1983.5466308594, -1147.0795898438, 21.527933120728)
                    end
                    imgui.SameLine()
                    if imgui.Button('Rifa', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2151.1638183594, -1815.1422119141, 13.546875)
                    end
                    imgui.Text('')
                    if imgui.Button('Night Wolve', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2201.328125, -1180.2880859375, 25.891353607178)
                    end
                    imgui.SameLine()
                    if imgui.Button('Aztec', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2532.2927246094, -1988.2835693359, 13.554044723511)
                    end
                    imgui.SameLine()
                    if imgui.Button('Vagos', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2749.142578125, -1599.9002685547, 13.059021949768)
                    end
                end
            elseif teleport == 3 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
            if imgui.Button(u8'Центр гетто', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 2226.0222167969, -1725.5418701172, 13.555264472961)
            end
            imgui.SameLine()
            if imgui.Button(u8'Центральный банк', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 1480.9249267578, -1768.8309326172, 18.795755386353)
            end
            imgui.SameLine()
            if imgui.Button(u8'Центральный рынок' , imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 1120.0362548828, -1437.4169921875, 15.796875)
            end
            imgui.Text('')
            if imgui.Button(u8'Черный рынок', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 2537.1428222656, -1446.6030273438, 24)
            end
            imgui.SameLine()
            if imgui.Button(u8'Авто базар', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, -2119.9887695313, -836.63293457031, 32.0234375)
            end
            imgui.SameLine()
            if imgui.Button(u8'ждлс 1', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 1754.2673339844, -1894.0520019531, 13.556971549988)
            end
            imgui.Text('')
            if imgui.Button(u8'ждлс 2', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 1153.8924560547, -1772.6787109375, 16.599193572998)
            end
            imgui.SameLine()
            if imgui.Button(u8'ждлв', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 2850.9326171875, 1292.1201171875, 11.724052429199)
            end
            imgui.SameLine()
            if imgui.Button(u8'ждлв2', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, -73.763969421387, 1222.7767333984, 19.723226547241)
            end
            imgui.Text('')
            if imgui.Button(u8'ждсф', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, -1971.9683837891, 125.35453796387, 27.6875)
            end
            imgui.SameLine()
            if imgui.Button(u8'казино', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 2034.5921630859, 1027.9523925781, 12.390121459961)
            end
            imgui.SameLine()           
            if imgui.Button(u8'стриптиз клуб', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 2488.9484863281, 2123.5939941406, 10.8203125)
            end 
            imgui.Text('')
            if imgui.Button(u8'Нефтевышки', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, 408.11224365234, 1377.2572021484, 9.8997344970703)
            end
            imgui.SameLine()        
            if imgui.Button(u8'сдача бочек', imgui.ImVec2(275, 100)) then
                setCharCoordinates(PLAYER_PED, -2064.1201171875, 1337.0283203125, 7.1241970062256)
            end             
        end
            elseif teleport == 4 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'1 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 4
                end
                imgui.SameLine()
                if imgui.Button(u8'2 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 5
                end
                imgui.SameLine()
                if imgui.Button(u8'3 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 6
                end
                if imgui.Button(u8'Джереми', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 1772.4508056641, -1892.7265625, 13.552840232849)
                end
                imgui.SameLine()
                if imgui.Button(u8'мерия', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 1494.8804931641, -1286.2418212891, 14.511383056641)
                end
                imgui.SameLine()
                if imgui.Button(u8'ферма', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -81.132621765137, 91.032592773438, 3.1171875)
                end
                imgui.Text('')
                if imgui.Button(u8'сдача сена', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -106.51016998291, 104.97875213623, 3.1171875)
                end
                imgui.SameLine()
                if imgui.Button(u8'грузчики', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 1977.2808837891, -1969.560546875, 13.582542419434)
                end
                imgui.SameLine()
                if imgui.Button(u8'сдача груза', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 2011.6962890625, -1988.0456542969, 13.546875)
                end
                imgui.Text('')
                if imgui.Button(u8'автошкола', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -2044.1539306641, -87.42081451416, 35.164073944092)
                end
                imgui.SameLine()
                if imgui.Button(u8'"Хватит сложной работой"', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 670.66607666016, -1577.4548339844, 14.306014060974)
                end
            end
            elseif teleport == 5 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'1 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 4
                end
                imgui.SameLine()
                if imgui.Button(u8'2 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 5
                end
                imgui.SameLine()
                if imgui.Button(u8'3 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 6
                end
                if imgui.Button(u8'Телепорт до квестового персонажа', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 1315.0285644531, 327.19131469727, 19.5546875)
                end
                imgui.Text(u8'а дальше я хз, ждите в некст версии')
                end
            elseif teleport == 6 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'1 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 4
                end
                imgui.SameLine()
                if imgui.Button(u8'2 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 5
                end
                imgui.SameLine()
                if imgui.Button(u8'3 квестовый персонаж', imgui.ImVec2(280, 50)) then
                    teleport = 6
                end
                imgui.Text(u8'а дальше я хз, ждите в некст версии')
                end
            elseif teleport == 7 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'военка лс', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 2703.337890625, -2392.6147460938, 13.6328125)
                end
                imgui.SameLine()
                if imgui.Button(u8'военка сф', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1553.5137939453, 486.89724731445, 7.1796875)
                end
                imgui.SameLine()
                if imgui.Button(u8'ТСР', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 114.72026062012, 1955.6822509766, 19.045070648193)
                end
                imgui.Text('')
                if imgui.Button(u8'Корабль военки сф', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1403.0935058594, 495.72647094727, 3.0390625)
                end
                imgui.SameLine()
                if imgui.Button(u8'материалы военки лс 1', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 2742.4387207031, -2454.7248535156, 13.86225605011)
                end
                imgui.SameLine()
                if imgui.Button(u8'материалы военки лс 2', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 2799.2836914063, -2393.0471191406, 13.95600605011)
                end
                imgui.Text('')
                if imgui.Button(u8'материалы военки сф 1', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1328.8974609375, 476.31945800781, 7.1809163093567)
                end
                imgui.SameLine()        
                if imgui.Button(u8'материалы военки сф 2', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1295.5637207031, 491.30435180664, 11.1953125)
                end
                imgui.SameLine()           
                if imgui.Button(u8'материалы военки сф 3', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1291.5606689453, 501.64639282227, 11.1953125)
                end  
                imgui.Text('')
                if imgui.Button(u8'материалы военки сф 4', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1397.88671875, 502.6005859375, 11.3046875)
                end
                imgui.SameLine()   
                if imgui.Button(u8'материалы военки сф 5', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1410.6760253906, 492.85931396484, 3.0390625)
                end
                imgui.SameLine()
                if imgui.Button(u8'материалы тср 1', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 113.39783477783, 1895.7532958984, 20.136262893677)
                end    
                imgui.Text('')
                if imgui.Button(u8'материалы тср 2', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 107.77785491943, 1866.1091308594, 17.792417526245)
                end
                imgui.SameLine()
                if imgui.Button(u8'материалы тср 3', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 106.37536621094, 1855.2613525391, 17.683786392212)
                end
            end
            elseif teleport == 8 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                    if imgui.Button(u8'притон 1', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2164.58203125, -1683.3426513672, 15.0859375)
                    end
                    imgui.SameLine()
                    if imgui.Button(u8'притон 2', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 1812.2587890625, -1997.0659179688, 13.554395675659)
                    end
                    imgui.SameLine()
                    if imgui.Button(u8'притон 3', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2309.7229003906, -2016.4920654297, 13.542916297913)
                    end
                    imgui.Text('')
                    if imgui.Button(u8'притон 4', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2347.5349121094, -1924.3132324219, 13.546875)
                    end
                    imgui.SameLine()
                    if imgui.Button(u8'притон 5', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2172.6801757813, -1496.7308349609, 23.983640670776)
                    end
                    imgui.SameLine()
                    if imgui.Button(u8'притон 6', imgui.ImVec2(275, 100)) then
                        setCharCoordinates(PLAYER_PED, 2594.4372558594, -949.66632080078, 81.688507080078)
                    end
                    
                end
            elseif teleport == 9 then
                imgui.SetCursorPos(imgui.ImVec2(175, 100))
                if imgui.BeginChild('Name##', imgui.ImVec2(855, 390), true) then
                if imgui.Button(u8'варлоки', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -2190.5993652344, -2349.5346679688, 30.625)
                end
                imgui.SameLine()
                if imgui.Button(u8'якудза', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -2461.673828125, 133.42585754395, 35.171875)
                end
                imgui.SameLine()
                if imgui.Button(u8'ЛКН', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 1460.3243408203, 2774.7702636719, 10.8203125)
                end
                imgui.Text('')
                if imgui.Button(u8'РМ', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, 940.13262939453, 1730.5462646484, 8.8515625)
                end
                imgui.SameLine()
                if imgui.Button(u8'байкеры', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1939.5780029297, 2380.0986328125, 49.6953125)
                end
                imgui.SameLine()
                if imgui.Button(u8'корабль (для мафий) 1', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1463.3442382813, 1491.9530029297, 8.2578125)
                end         
                imgui.Text('')  
                if imgui.Button(u8'корабль (для мафий) 2', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1409.2487792969, 1488.1684570313, 7.1091651916504)
                end           
                imgui.SameLine() 
                if imgui.Button(u8'корабль (для мафий) 3', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1368.5633544922, 1489.6203613281, 11.0390625)
                end
                imgui.SameLine()            
                if imgui.Button(u8'корабль (для мафий) 4', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1432.5024414063, 1489.0223388672, 1.8671875)
                end        
                imgui.Text('') 
                if imgui.Button(u8'корабль (сдача коробок)', imgui.ImVec2(275, 100)) then
                    setCharCoordinates(PLAYER_PED, -1446.4644775391, 1501.5092773438, 1.7366480827332)
                end     
            end
        end
    end
    imgui.End()
end)

local newFrame = imgui.OnFrame(
    function() return rapidd[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(300, 300), imgui.Cond.FirstUseEver)
        if imgui.Begin('Rapid', rapidd) then
            if imgui.Checkbox(u8'рапид х2', lol.rapidxx) then
                if lol.rapidxx[0] then
                    rapid()
                    ini.rapid.rapidxx = lol.rapidxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х3', lol.rapidxxx) then
                if lol.rapidxxx[0] then
                    rapid()
                    ini.rapid.rapidxxx = lol.rapidxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х4', lol.rapidxxxx) then
                if lol.rapidxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxx = lol.rapidxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х5', lol.rapidxxxxx) then
                if lol.rapidxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxx = lol.rapidxxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х6', lol.rapidxxxxxx) then
                if lol.rapidxxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxxx = lol.rapidxxxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х7', lol.rapidxxxxxxx) then
                if lol.rapidxxxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxxxx = lol.rapidxxxxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х8', lol.rapidxxxxxxxx) then
                if lol.rapidxxxxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxxxxx = lol.rapidxxxxxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х9', lol.rapidxxxxxxxxx) then
                if lol.rapidxxxxxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxxxxxx = lol.rapidxxxxxxxxx[0]
                    iniSave()
                end
            end
            if imgui.Checkbox(u8'рапид х10', lol.rapidxxxxxxxxxx) then
                if lol.rapidxxxxxxxxxx[0] then
                    rapid()
                    ini.rapid.rapidxxxxxxxxxx = lol.rapidxxxxxxxxxx[0]
                    iniSave()
                end
            end
        end
        imgui.End()
    end)
    local newFrame = imgui.OnFrame(
        function() return fastbegg[0] end,
        function(player)
            imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(300, 300), imgui.Cond.FirstUseEver)
            if imgui.Begin('Fast beg', fastbegg) then
                if imgui.Checkbox(u8'Быстрый бег х2', lol.begxx) then
                    if lol.begxx[0] then
                        beg()
                        ini.fastbeg.begxx = lol.begxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х3', lol.begxxx) then
                    if lol.begxxx[0] then
                        beg()
                        ini.fastbeg.begxxx = lol.begxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х4', lol.begxxxx) then
                    if lol.begxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxx = lol.begxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х5', lol.begxxxxx) then
                    if lol.begxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxx = lol.begxxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х6', lol.begxxxxxx) then
                    if lol.begxxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxxx = lol.begxxxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х7', lol.begxxxxxxx) then
                    if lol.begxxxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxxxx = lol.begxxxxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х8', lol.begxxxxxxxx) then
                    if lol.begxxxxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxxxxx = lol.begxxxxxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х9', lol.begxxxxxxxxx) then
                    if lol.begxxxxxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxxxxxx = lol.bexgxxxxxxxxx[0]
                        iniSave()
                    end
                end
                if imgui.Checkbox(u8'Быстрый бег х10', lol.begxxxxxxxxxx) then
                    if lol.begxxxxxxxxxx[0] then
                        beg()
                        ini.fastbeg.begxxxxxxxxxx = lol.begxxxxxxxxxx[0]
                        iniSave()
                    end
                end
            end     
        imgui.End()
    end)
    local newFrame = imgui.OnFrame(
        function() return pizda[0] end,
        function(player)
            imgui.SetNextWindowPos(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
            if imgui.Begin(u8'Настройка', pizda) then
                imgui.SliderFloat(u8'поворот скорости по х', lol.one, -10, 100)
                imgui.SliderFloat(u8'поворот скорости по y', lol.two, -10, 100)
                imgui.SliderFloat(u8'поворот скорости по z', lol.three, -10, 100)
                imgui.SliderFloat(u8'боковая скорость по х', lol.four, -10, 100)
                imgui.SliderFloat(u8'боковая скорость по y', lol.five, -10, 100)
                imgui.SliderFloat(u8'боковая скорость по z', lol.six, -10, 100)
                imgui.SliderFloat(u8'ускорение машины по x', lol.seven, -10, 100)
                imgui.SliderFloat(u8'ускорение машины по y', lol.eight, -10, 100)
                imgui.SliderFloat(u8'ускорение машине по z', lol.nine, -10, 100)
                imgui.SliderFloat(u8'поворот + ускорение машины  по x', lol.ten, -10, 100)
                imgui.SliderFloat(u8'поворот + ускорение машины по y', lol.eleven, -10, 100)
                imgui.SliderFloat(u8'поворот + ускорение машины по z', lol.twelve, -10, 100)
                imgui.SliderFloat(u8'дистанция', lol.dist, -10, 100)
                imgui.SliderFloat(u8'задержка', lol.twelve, -10, 100)
            end      
        imgui.End()
    end)

    function sampev.onAimSync(playerId, data)
        if samplua.onAimSync[0] then
            return false
        end
    end
    function sampev.onApplyActorAnimation(actorId, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
        if samplua.onApplyActorAnimation[0] then
            return false
        end
    end
    function sampev.onApplyPlayerAnimation()
        if samplua.onApplyPlayerAnimation[0] then
            return false
        end
    end
    function sampev.onCreateObject()
        if samplua.onCreateObject[0] then
            return false
        end
    end
    function sampev.onCreatePickup()
        if samplua.onCreatePickup[0] then
            return false
        end
    end
    function sampev.onDisplayGameText()
        if samplua.onDisplayGameText[0] then
            return false
        end
    end
    function sampev.onPlayerStreamIn()
        if samplua.onPlayerStreamIn[0] then
            return false
        end
    end
    function sampev.onRemovePlayerFromVehicle()
        if samplua.onRemovePlayerFromVehicle[0] then
            return false
        end
    end
    function sampev.onSendClickTextDraw()
        if samplua.onSendClickTextDraw[0] then
            return false
        end
    end
    function sampev.onSendClientJoin()
        if samplua.onSendClientJoin[0] then
            return false
        end
    end
    function sampev.onSendCommand()
        if samplua.onSendCommand[0] then
            return false
        end
    end
    function sampev.onSendSpawn()
        if samplua.onSendSpawn[0] then
            return false
        end
    end
    function sampev.onSendDeathNotification()
        if samplua.onSendDeathNotification[0] then
            return false
        end
    end
    function sampev.onSendDialogResponse()
        if samplua.onSendDialogResponse[0] then
            return false
        end
    end
    function sampev.onSendVehicleTuningNotification()
        if samplua.onSendVehicleTuningNotification[0] then
            return false
        end
    end
    function sampev.onSendChat()
        if samplua.onSendChat[0] then
            return false
        end
    end
    function sampev.onSendClientCheckResponse()
        if samplua.onSendClientCheckResponse[0] then
            return false
        end
    end
    function sampev.onSendVehicleDamaged()
        if samplua.onSendVehicleDamaged[0] then
            return false
        end
    end
    function sampev.onSendEditAttachedObject()
        if samplua.onSendEditAttachedObject[0] then
            return false
        end
    end
    function sampev.onSendEditObject()
        if samplua.onSendEditObject[0] then
            return false
        end
    end
    function sampev.onSendInteriorChangeNotification()
        if samplua.onSendInteriorChangeNotification[0] then
            return false
        end
    end
    function sampev.onSendMapMarker()
        if samplua.onSendMapMarker[0] then
            return false
        end
    end
    function sampev.onSendRequestClass()
        if samplua.onSendRequestClass[0] then
            return false
        end
    end
    function sampev.onSendRequestSpawn()
        if samplua.onSendRequestSpawn[0] then
            return false
        end
    end
    function sampev.onSendPickedUpPickup()
        if samplua.onSendPickedUpPickup[0] then
            return false
        end
    end
    function sampev.onSendMenuSelect()
        if samplua.onSendMenuSelect[0] then
            return false
        end
    end
    function sampev.onSendVehicleDestroyed()
        if samplua.onSendVehicleDestroyed[0] then
            return false
        end
    end
    function sampev.onSendQuitMenu()
        if samplua.onSendQuitMenu[0] then
            return false
        end
    end
    function sampev.onSendExitVehicle()
        if samplua.onSendExitVehicle[0] then
            return false
        end
    end
    function sampev.onSendUpdateScoresAndPings()
        if samplua.onSendUpdateScoresAndPings[0] then
            return false
        end
    end
    function sampev.onSendGiveDamage()
        if samplua.onSendGiveDamage[0] then
            return false
        end
    end
    function sampev.onSendTakeDamage()
        if samplua.onSendTakeDamage[0] then
            return false
        end
    end
    function sampev.onSendMoneyIncreaseNotification()
        if samplua.onSendMoneyIncreaseNotification[0] then
            return false
        end
    end
    function sampev.onSendNPCJoin()
        if samplua.onSendNPCJoin[0] then
            return false
        end
    end
    function sampev.onSendServerStatisticsRequest()
        if samplua.onSendServerStatisticsRequest[0] then
            return false
        end
    end
    function sampev.onSendPickedUpWeapon()
        if samplua.onSendPickedUpWeapon then
            return false
        end
    end
    function sampev.onSendCameraTargetUpdate()
        if samplua.onSendCameraTargetUpdate[0] then
            return false
        end
    end
    function sampev.onSendGiveActorDamage()
        if samplua.onSendGiveActorDamage[0] then
            return false
        end
    end
    function sampev.onInitGame()
        if samplua.onInitGame[0] then
            return false
        end
    end
    function sampev.onPlayerJoin()
        if samplua.onPlayerJoin[0] then
            return false
        end
    end
    function sampev.onPlayerQuit()
        if samplua.onPlayerQuit[0] then
            return false
        end
    end
    function sampev.onRequestClassResponse()
        if samplua.onRequestClassResponse[0] then
            return false
        end
    end
    function sampev.onRequestSpawnResponse()
        if samplua.onRequestSpawnResponse[0] then
            return false
        end
    end
    function sampev.onSetPlayerName()
        if samplua.onSetPlayerName[0] then
            return false
        end
    end
    function sampev.onSetPlayerPos()
        if samplua.onSetPlayerPos[0] then
            return false
        end
    end
    function sampev.onSetPlayerPosFindZ()
        if samplua.onSetPlayerPosFindZ[0] then
            return false
        end
    end
    function sampev.onSetPlayerHealth()
        if samplua.onSetPlayerHealth[0] then
            return false
        end
    end
    function sampev.onTogglePlayerControllable()
        if samplua.onTogglePlayerControllable[0] then
            return false
        end
    end
    function sampev.onPlaySound()
        if samplua.onPlaySound[0] then
            return false
        end
    end
    function sampev.onSetWorldBounds()
        if samplua.onSetWorldBounds[0] then
            return false
        end
    end
    function sampev.onGivePlayerMoney()
        if samplua.onGivePlayerMoney[0] then
            return false
        end
    end
    function sampev.onSetPlayerFacingAngle()
        if samplua.onSetPlayerFacingAngle[0] then
            return false
        end
    end
    function sampev.onResetPlayerMoney()
        if samplua.onResetPlayerMoney[0] then
            return false
        end
    end
    function sampev.onResetPlayerWeapons()
        if samplua.onResetPlayerWeapons[0] then
            return false
        end
    end
    function sampev.onGivePlayerWeapon()
        if samplua.onGivePlayerWeapon[0] then
            return false
        end
    end
    function sampev.onCancelEdit()
        if samplua.onCancelEdit[0] then
            return false
        end
    end
    function sampev.onSetPlayerTime()
        if samplua.onSetPlayerTime[0] then
            return false
        end
    end
    function sampev.onSetToggleClock()
        if samplua.onSetToggleClock[0] then
            return false
        end
    end
    function sampev.onSetShopName()
        if samplua.onSetShopName[0] then
            return false
        end
    end
    function sampev.onSetPlayerSkillLevel()
        if samplua.onSetPlayerSkillLevel[0] then
            return false
        end
    end
    function sampev.onSetPlayerDrunk()
        if samplua.onSetPlayerDrunk[0] then
            return false
        end
    end
    function sampev.onCreate3DText()
        if samplua.onCreate3DText[0] then
            return false
        end
    end
    function sampev.onDisableCheckpoint()
        if samplua.onDisableCheckpoint[0] then
            return false
        end
    end
    function sampev.onSetRaceCheckpoint()
        if samplua.onSetRaceCheckpoint[0] then
            return false
        end
    end
    function sampev.onDisableRaceCheckpoint()
        if samplua.onDisableRaceCheckpoint[0] then
            return false
        end
    end
    function sampev.onGamemodeRestart()
        if samplua.onGamemodeRestart[0] then
            return false
        end
    end
    function sampev.onPlayAudioStream()
        if samplua.onPlayAudioStream[0] then
            return false
        end
    end
    function sampev.onStopAudioStream()
        if samplua.onStopAudioStream[0] then
            return false
        end
    end
    function sampev.onRemoveBuilding()
        if samplua.onRemoveBuilding[0] then
            return false
        end
    end
    function sampev.onSetObjectPosition()
        if samplua.onSetObjectPosition[0] then
            return false
        end
    end
    function sampev.onSetObjectRotation()
        if samplua.onSetObjectRotation[0] then
            return false
        end
    end
    function sampev.onDestroyObject()
        if samplua.onDestroyObject[0] then
            return false
        end
    end
    function sampev.onPlayerDeathNotification()
        if samplua.onPlayerDeathNotification[0] then
            return false
        end
    end
    function sampev.onSetMapIcon()
        if samplua.onSetMapIcon[0] then
            return false
        end
    end
    function sampev.onRemoveVehicleComponent()
        if samplua.onRemoveVehicleComponent[0] then
            return false
        end
    end
    function sampev.onRemove3DTextLabel()
        if samplua.onRemove3DTextLabel[0] then
            return false
        end
    end
    function sampev.onPlayerChatBubble()
        if samplua.onPlayerChatBubble[0] then
            return false
        end
    end
    function sampev.onUpdateGlobalTimer()
        if samplua.onUpdateGlobalTimer[0] then
            return false
        end
    end
    function sampev.onShowDialog()
        if samplua.onShowDialog[0] then
            return false
        end
    end
    function sampev.onDestroyPickup()
        if samplua.onDestroyPickup[0] then
            return false
        end
    end
    function sampev.onLinkVehicleToInterior()
        if samplua.onLinkVehicleToInterior[0] then
            return false
        end
    end
    function sampev.onSetPlayerArmour()
        if samplua.onSetPlayerArmour[0] then
            return false
        end
    end
    function sampev.onSetPlayerArmedWeapon()
        if samplua.onSetPlayerArmedWeapon[0] then
            return false
        end
    end
    function sampev.onSetSpawnInfo()
        if samplua.onSetSpawnInfo[0] then
            return false
        end
    end
    function sampev.onSetPlayerTeam()
        if samplua.onSetPlayerTeam[0] then
            return false
        end
    end
    function sampev.onPutPlayerInVehicle()
        if samplua.onPutPlayerInVehicle[0] then
            return false
        end
    end
    function sampev.onRemovePlayerFromVehicle()
        if samplua.onRemovePlayerFromVehicle[0] then
            return false
        end
    end
    function sampev.onSetPlayerColor()
        if samplua.onSetPlayerColor[0] then
            return false
        end
    end
    function sampev.onForceClassSelection()
        if samplua.onForceClassSelection[0] then
            return false
        end
    end
    function sampev.onAttachObjectToPlayer()
        if samplua.onAttachCameraToObject[0] then
            return false
        end
    end
    function sampev.onInitMenu()
        if samplua.onInitMenu[0] then
            return false
        end
    end
    function sampev.onShowMenu()
        if samplua.onShowMenu[0] then
            return false
        end
    end
    function sampev.onHideMenu()
        if samplua.onHideMenu[0] then
            return false
        end
    end
    function sampev.onCreateExplosion()
        if samplua.onCreateExplosion[0] then
            return false
        end
    end
    function sampev.onShowPlayerNameTag()
        if samplua.onShowPlayerNameTag[0] then
            return false
        end
    end
    function sampev.onAttachCameraToObject()
        if samplua.onAttachCameraToObject[0] then
            return false
        end
    end
    function sampev.onInterpolateCamera()
        if samplua.onInterpolateCamera[0] then
            return false
        end
    end
    function sampev.onGangZoneStopFlash()
        if samplua.onGangZoneStopFlash[0] then
            return false
        end
    end
    function sampev.onClearPlayerAnimation()
        if samplua.onClearPlayerAnimation[0] then
            return false
        end
    end
    function sampev.onSetPlayerSpecialAction()
        if samplua.onSetPlayerSpecialAction[0] then
            return false
        end
    end
    function sampev.onSetPlayerFightingStyle()
        if samplua.onSetPlayerFightingStyle[0] then
            return false
        end
    end
    function sampev.onSetPlayerVelocity()
        if samplua.onSetPlayerVelocity[0] then
            return false
        end
    end
    function sampev.onSetVehicleVelocity()
        if samplua.onSetVehicleVelocity[0] then
            return false
        end
    end
    function sampev.onServerMessage()
        if samplua.onServerMessage[0] then
            return false
        end
    end
    function sampev.onSetWorldTime()
        if samplua.onSetWorldTime[0] then
            return false
        end
    end
    --[[function sampev.onMoveObject()
        if samplua then
            return false
        end
    end
    function sampev.onEnableStuntBonus()
        if samplua then
            return false
        end
    end
    function sampev.onTextDrawSetString()
        if samplua then
            return false
        end
    end
    function sampev.onSetCheckpoint()
        if samplua then
            return false
        end
    end
    function sampev.onCreateGangZone()
        if samplua then
            return false
        end
    end
    function sampev.onPlayCrimeReport()
        if samplua then
            return false
        end
    end
    function sampev.onGangZoneDestroy()
        if samplua then
            return false
        end
    end
    function sampev.onGangZoneFlash()
        if samplua then
            return false
        end
    end
    function sampev.onStopObject()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleNumberPlate()
        if samplua then
            return false
        end
    end
    function sampev.onTogglePlayerSpectating()
        if samplua then
            return false
        end
    end
    function sampev.onSpectatePlayer()
        if samplua then
            return false
        end
    end
    function sampev.onSpectateVehicle()
        if samplua then
            return false
        end
    end
    function sampev.onShowTextDraw()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerWantedLevel()
        if samplua then
            return false
        end
    end
    function sampev.onTextDrawHide()
        if samplua then
            return false
        end
    end
    function sampev.onRemoveMapIcon()
        if samplua then
            return false
        end
    end
    function sampev.onSetWeaponAmmo()
        if samplua then
            return false
        end
    end
    function sampev.onSetGravity()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleHealth()
        if samplua then
            return false
        end
    end
    function sampev.onAttachTrailerToVehicle()
        if samplua then
            return false
        end
    end
    function sampev.onDetachTrailerFromVehicle()
        if samplua then
            return false
        end
    end
    function sampev.onSetWeather()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerSkin()
        if samplua then
            return false
        end
    end
    function sampev.onSetInterior()
        if samplua then
            return false
        end
    end
    function sampev.onSetCameraPosition()
        if samplua then
            return false
        end
    end
    function sampev.onSetCameraLookAt()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehiclePosition()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleAngle()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleParams()
        if samplua then
            return false
        end
    end
    function sampev.onSetCameraBehind()
        if samplua then
            return false
        end
    end
    function sampev.onChatMessage()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionRejected()
        if samplua then
            return false
        end
    end
    function sampev.onPlayerStreamOut()
        if samplua then
            return false
        end
    end
    function sampev.onVehicleStreamIn()
        if samplua then
            return false
        end
    end
    function sampev.onVehicleStreamOut()
        if samplua then
            return false
        end
    end
    function sampev.onPlayerDeath()
        if samplua then
            return false
        end
    end
    function sampev.onPlayerEnterVehicle()
        if samplua then
            return false
        end
    end
    function sampev.onUpdateScoresAndPings()
        if samplua then
            return false
        end
    end
    function sampev.onSetObjectMaterial()
        if samplua then
            return false
        end
    end
    function sampev.onCreateActor()
        if samplua then
            return false
        end
    end
    function sampev.onToggleSelectTextDraw()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleParamsEx()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerAttachedObject()
        if samplua then
            return false
        end
    end
    function sampev.onClientCheck()
        if samplua then
            return false
        end
    end
    function sampev.onDestroyActor()
        if samplua then
            return false
        end
    end
    function sampev.onDestroyWeaponPickup()
        if samplua then
            return false
        end
    end
    function sampev.onEditAttachedObject()
        if samplua then
            return false
        end
    end
    function sampev.onToggleCameraTargetNotifying()
        if samplua then
            return false
        end
    end
    function sampev.onEnterSelectObject()
        if samplua then
            return false
        end
    end
    function sampev.onPlayerExitVehicle()
        if samplua then
            return false
        end
    end
    function sampev.onVehicleTuningNotification()
        if samplua then
            return false
        end
    end
    function sampev.onServerStatisticsResponse()
        if samplua then
            return false
        end
    end
    function sampev.onEnterEditObject()
        if samplua then
            return false
        end
    end
    function sampev.onVehicleDamageStatusUpdate()
        if samplua then
            return false
        end
    end
    function sampev.onDisableVehicleCollisions()
        if samplua then
            return false
        end
    end
    function sampev.onToggleWidescreen()
        if samplua then
            return false
        end
    end
    function sampev.onSetVehicleTires()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerDrunkVisuals()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerDrunkHandling()
        if samplua then
            return false
        end
    end
    function sampev.onApplyActorAnimation()
        if samplua then
            return false
        end
    end
    function sampev.onClearActorAnimation()
        if samplua then
            return false
        end
    end
    function sampev.onSetActorFacingAngle()
        if samplua then
            return false
        end
    end
    function sampev.onSetActorPos()
        if samplua then
            return false
        end
    end
    function sampev.onSetActorHealth()
        if samplua then
            return false
        end
    end
    function sampev.onSetPlayerObjectNoCameraCol()
        if samplua then
            return false
        end
    end
    function sampev.onSendRconCommand()
        if samplua then
            return false
        end
    end
    function sampev.onSendStatsUpdate()
        if samplua then
            return false
        end
    end
    function sampev.onSendPlayerSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendVehicleSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendPassengerSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendAimSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendUnoccupiedSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendTrailerSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendBulletSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendSpectatorSync()
        if samplua then
            return false
        end
    end
    function sampev.onSendWeaponsUpdate()
        if samplua then
            return false
        end
    end
    function sampev.onSendAuthenticationResponse()
        if samplua then
            return false
        end
    end
    function sampev.onPlayerSync()
        if samplua then
            return false
        end
    end
    function sampev.onVehicleSync()
        if samplua then
            return false
        end
    end
    function sampev.onMarkersSync()
        if samplua then
            return false
        end
    end
    function sampev.onAimSync()
        if samplua then
            return false
        end
    end
    function sampev.onBulletSync()
        if samplua then
            return false
        end
    end
    function sampev.onUnoccupiedSync()
        if samplua then
            return false
        end
    end
    function sampev.onTrailerSync()
        if samplua then
            return false
        end
    end
    function sampev.onPassengerSync()
        if samplua then
            return false
        end
    end
    function sampev.onAuthenticationRequest()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionRequestAccepted()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionLost()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionBanned()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionAttemptFailed()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionNoFreeSlot()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionPasswordInvalid()
        if samplua then
            return false
        end
    end
    function sampev.onConnectionClosed()
        if samplua then
            return false
        end  
    end]]

    function getCarRealMatrix(handle)
        local entity = getCarPointer(handle)
        if entity ~= 0 then
            local carMatrix = memory.getuint32(entity + 0x14, true)
            if carMatrix ~= 0 then
                local rx = memory.getfloat(carMatrix + 0 * 4, true)
                local ry = memory.getfloat(carMatrix + 1 * 4, true)
                local rz = memory.getfloat(carMatrix + 2 * 4, true)
    
                local dx = memory.getfloat(carMatrix + 4 * 4, true)
                local dy = memory.getfloat(carMatrix + 5 * 4, true)
                local dz = memory.getfloat(carMatrix + 6 * 4, true)
                return rx, ry, rz, dx, dy, dz
            end
        end
    end
    
    function sampev.onDisplayGameText(style, time, text)
        if settings.sec[0] and style == 3 and time == 1000 and text:find("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %d+ Sec%.") then
            c, _ = math.modf(tonumber(text:match("Jailed (%d+)")) / 60)
            if c < 60 then 
            return {style, time, string.format("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %s Sec = %s Min", text:match("Jailed (%d+)"), c)}
            else
            h, _ = math.modf(tonumber(text:match("Jailed (%d+)")) / 60/60)
            return {style, time, string.format("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %s Sec = %s Min = %s Hour", text:match("Jailed (%d+)"), c, h)}
            end
        end
    end
    
    function sampev.onShowTextDraw(id, data)
        if settings.sec[0] and data.text:find("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %d+ Sec%.") then
            local c, _ = math.modf(tonumber(data.text:match("Jailed (%d+)")) / 60)
            if c < 60 then 
                data.text = string.format("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %s Sec = %s Min", data.text:match("Jailed (%d+)"), c)
            else
                local h, _ = math.modf(tonumber(data.text:match("Jailed (%d+)")) / 60/60)
                data.text = string.format("~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~g~Jailed %s Sec = %s Min = %s Hour", data.text:match("Jailed (%d+)"), c, h)
            end
            return {id, data}
        end
    end

    function sampev.onCreateObject(id, data)
        if lol.ash[0] then
        elseif data.modelId == 968 or data.modelId == 966 then
            return false
        end
    end

    function sampev.onCreatePickup(id, model, type, pos)
        for k, pickup in pairs(pickups) do
            if pickup.id == id then
                return {id, model, type, pos}
            end
        end
        table.insert(pickups, {id = id, pos = pos})
    end

    function nofal()
        lua_thread.create(function()
    while lol.nofall[0] do -- no falltaskPlayAnim(playerPed HANDSUP PED 4.0 0 0 0 0 4)
        wait(0)
        if isCharPlayingAnim(playerPed, 'KO_SKID_BACK') or isCharPlayingAnim(playerPed, 'FALL_COLLAPSE') then
            clearCharTasksImmediately(playerPed)
                end
            end
        end)
    end

    function antistun()
        lua_thread.create(function()
    while lol.antistun[0] do
        wait(0)
        setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmBK", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmFT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmLT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmBK", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmFT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmRT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmBK", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmFT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmLT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmBK", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmFT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmRT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmBK", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmFT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmLT", 999)
        setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmRT", 999)
            end
        end)
    end
    
    function beg()
    lua_thread.create(function()
        while lol.begxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 2)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_GANG2', 2)
            setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 2)
            setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 2)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG2', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG2', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 2)
            setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 2)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 2)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 2)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 2)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 2)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 2)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 2)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 2)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 2)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 2)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 2)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 2)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 2)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 2)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 2)
            setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 2)
            setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 2)
        end
    end)
    lua_thread.create(function()
        while lol.begxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 3)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_GANG3', 3)
            setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 3)
            setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 3)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG3', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG3', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 3)
            setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 3)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 3)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 3)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 3)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 3)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 3)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 3)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 3)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 3)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 3)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 3)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 3)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 3)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 3)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 3)
            setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 3)
            setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 3)
        end
    end)
        lua_thread.create(function()
        while lol.begxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 4)
            setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_GANG4', 4)
            setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 4)
            setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 4)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG4', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_GANG4', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 4)
            setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 4)
            setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 4)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 4)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 4)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 4)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 4)
            setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 4)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 4)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 4)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 4)
            setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 4)
            setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 4)
            setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 4)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 4)
            setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 4)
            setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 4)
            setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 4)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 5)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG5', 5)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 5)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 5)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG5', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG5', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 5)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 5)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 5)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 5)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 5)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 5)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 5)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 5)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 5)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 5)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 5)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 5)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 5)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 5)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 5)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 5)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 5)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 5)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 6)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG6', 6)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 6)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 6)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG6', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG6', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 6)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 6)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 6)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 6)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 6)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 6)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 6)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 6)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 6)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 6)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 6)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 6)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 6)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 6)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 6)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 6)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 6)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 6)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 7)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG7', 7)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 7)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 7)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG7', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG7', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 7)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 7)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 7)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 7)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 7)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 7)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 7)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 7)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 7)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 7)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 7)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 7)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 7)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 7)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 7)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 7)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 7)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 7)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 8)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG8', 8)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 8)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 8)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG8', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG8', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 8)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 8)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 8)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 8)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 8)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 8)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 8)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 8)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 8)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 8)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 8)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 8)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 8)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 8)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 8)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 8)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 8)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 8)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 9)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG9', 9)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 9)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 9)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG9', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG9', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 9)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 9)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 9)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 9)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 9)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 9)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 9)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 9)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 9)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 9)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 9)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 9)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 9)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 9)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 9)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 9)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 9)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 9)
            end
        end)
        lua_thread.create(function()
            while lol.begxxxxxxxxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, 'WALK_PLAYER', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHFWD', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNCROUCHBWD', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_BWD', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_FWD', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_L', 10)
                setCharAnimSpeed(PLAYER_PED, 'GUNMOVE_R', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_GANG10', 10)
                setCharAnimSpeed(PLAYER_PED, 'JOG_FEMALEA', 10)
                setCharAnimSpeed(PLAYER_PED, 'JOG_MALEA', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CIVI', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_CSAW', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FAT', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_FATOLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_OLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ROCKET', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_WUZI', 10)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_WUZI', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ARMED', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CIVI', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_CSAW', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_DRUNK', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FAT', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_FATOLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG10', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_GANG10', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_OLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_SHUFFLE', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ARMED', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_CSAW', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_START_ROCKET', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_WUZI', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKBUSY', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKFATOLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKNORM', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKOLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNFATOLD', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKPRO', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSEXY', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_WALKSHOP', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_1ARMED', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_ARMED', 10)
                setCharAnimSpeed(PLAYER_PED, 'RUN_PLAYER', 10)
                setCharAnimSpeed(PLAYER_PED, 'WALK_ROCKET', 10)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_IDLE', 10)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLESPRINT', 10)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_PULL', 10)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND', 10)
                setCharAnimSpeed(PLAYER_PED, 'CLIMB_STAND_FINISH', 10)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_BREAST', 10)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_CRAWL', 10)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_DIVE_UNDER', 10)
                setCharAnimSpeed(PLAYER_PED, 'SWIM_GLIDE', 10)
                setCharAnimSpeed(PLAYER_PED, 'MUSCLERUN', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUN', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNBUSY', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNPANIC', 10)
                setCharAnimSpeed(PLAYER_PED, 'WOMAN_RUNSEXY', 10)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_CIVI', 10)
                setCharAnimSpeed(PLAYER_PED, 'SPRINT_PANIC', 10)
                setCharAnimSpeed(PLAYER_PED, 'SWAT_RUN', 10)
                setCharAnimSpeed(PLAYER_PED, 'FATSPRINT', 10)
            end
        end)
    end
    
    function rapid()
        lua_thread.create(function()
        while lol.rapidxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 2)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 2)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 2)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 2)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 2)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 2)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 2)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 2)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 2)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 2)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 2)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 2)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 2)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 2)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 2)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 2)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 2)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 2)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 2)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 2)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 2)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 2)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 2)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 2)  
            end
        end)
        lua_thread.create(function()
            while lol.rapidxxx[0] do
                wait(0)
                setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 3)
                setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 3)
                setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 3)
                setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 3)
                setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 3)
                setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 3)
                setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 3)
                setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 3)
                setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 3)
                setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 3)
                setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 3)
                setCharAnimSpeed(PLAYER_PED, "TEC_fire", 3)
                setCharAnimSpeed(PLAYER_PED, "TEC_reload", 3)
                setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 3)
                setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 3)
                setCharAnimSpeed(PLAYER_PED, "UZI_fire", 3)
                setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 3)
                setCharAnimSpeed(PLAYER_PED, "UZI_reload", 3)
                setCharAnimSpeed(PLAYER_PED, "idle_rocket", 3)
                setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 3)
                setCharAnimSpeed(PLAYER_PED, "run_rocket", 3)
                setCharAnimSpeed(PLAYER_PED, "walk_rocket", 3)
                setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 3)
                setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 3)  
                end
            end)
                lua_thread.create(function()
        while lol.rapidxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 4)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 4)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 4)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 4)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 4)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 4)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 4)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 4)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 4)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 4)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 4)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 4)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 4)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 4)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 4)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 4)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 4)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 4)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 4)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 4)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 4)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 4)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 4)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 4)  
            end
        end)
            lua_thread.create(function()
        while lol.rapidxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 5)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 5)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 5)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 5)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 5)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 5)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 5)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 5)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 5)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 5)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 5)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 5)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 5)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 5)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 5)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 5)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 5)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 5)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 5)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 5)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 5)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 5)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 5)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 5)  
            end
        end)
        lua_thread.create(function()
        while lol.rapidxxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 6)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 6)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 6)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 6)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 6)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 6)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 6)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 6)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 6)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 6)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 6)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 6)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 6)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 6)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 6)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 6)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 6)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 6)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 6)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 6)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 6)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 6)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 6)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 6)  
            end
        end)
                lua_thread.create(function()
        while lol.rapidxxxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 7)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 7)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 7)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 7)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 7)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 7)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 7)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 7)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 7)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 7)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 7)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 7)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 7)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 7)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 7)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 7)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 7)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 7)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 7)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 7)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 7)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 7)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 7)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 7)  
            end
        end)
                lua_thread.create(function()
        while lol.rapidxxxxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 8)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 8)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 8)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 8)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 8)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 8)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 8)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 8)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 8)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 8)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 8)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 8)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 8)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 8)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 8)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 8)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 8)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 8)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 8)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 8)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 8)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 8)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 8)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 8)  
            end
        end)
                lua_thread.create(function()
        while lol.rapidxxxxxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 9)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 9)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 9)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 9)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 9)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 9)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 9)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 9)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 9)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 9)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 9)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 9)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 9)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 9)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 9)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 9)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 9)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 9)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 9)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 9)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 9)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 9)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 9)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 9)  
            end
        end)
                lua_thread.create(function()
        while lol.rapidxxxxxxxxxx[0] do
            wait(0)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROUCHFIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_FIRE_POOR", 10)
            setCharAnimSpeed(PLAYER_PED, "PYTHON_CROCUCHRELOAD", 10)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHFIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_CROUCHLOAD", 10)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_FIRE_POOR", 10)
            setCharAnimSpeed(PLAYER_PED, "RIFLE_LOAD", 10)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_CROUCHFIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "SHOTGUN_FIRE_POOR", 10)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_RELOAD", 10)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_CROUCH_FIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_FIRE", 10)
            setCharAnimSpeed(PLAYER_PED, "SILENCED_RELOAD", 10)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchfire", 10)
            setCharAnimSpeed(PLAYER_PED, "TEC_crouchreload" , 10)
            setCharAnimSpeed(PLAYER_PED, "TEC_fire", 10)
            setCharAnimSpeed(PLAYER_PED, "TEC_reload", 10)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchfire", 10)
            setCharAnimSpeed(PLAYER_PED, "UZI_crouchreload", 10)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire", 10)
            setCharAnimSpeed(PLAYER_PED, "UZI_fire_poor", 10)
            setCharAnimSpeed(PLAYER_PED, "UZI_reload", 10)
            setCharAnimSpeed(PLAYER_PED, "idle_rocket", 10)
            setCharAnimSpeed(PLAYER_PED, "Rocket_Fire", 10)
            setCharAnimSpeed(PLAYER_PED, "run_rocket", 10)
            setCharAnimSpeed(PLAYER_PED, "walk_rocket", 10)
            setCharAnimSpeed(PLAYER_PED, "WALK_start_rocket", 10)
            setCharAnimSpeed(PLAYER_PED, "WEAPON_sniper", 10)  
            end
        end)
    end

    function getPlayerStream(distance) 
        math.randomseed(os.time())
        for i = 0, sampGetMaxPlayerId() do
            if sampIsPlayerConnected(i) then
                local result, playerHandle = sampGetCharHandleBySampPlayerId(i)
                if result and getCharHealth(playerHandle) > 0 and not sampIsPlayerPaused(i) and i ~= sampGetPlayerIdByCharHandle(PLAYER_PED) then 
                    local PLAYER_POS = {getCharCoordinates(PLAYER_PED)}
                    local TARGET_POS = {getCharCoordinates(playerHandle)}
                    local BETWEEN = getDistanceBetweenCoords3d(PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3], TARGET_POS[1], TARGET_POS[2], TARGET_POS[3])
                    if BETWEEN < distance then 
                        return true, playerHandle, i
                    end
                end
            end
        end
        return false, nil, nil
    end

    function sampev.onSendPlayerSync(data)
        if lol.surf[0] then
            data.surfingVehicleId = 0
        end
        if lol.antidrop[0] then
            data.keysData = 0
        end
        if lol.antistuuun[0] and data.animationId == 1084 then
            data.animationFlags = 32772
            data.animationId = 1189
        end
        if invis.cloud[0] and getCar(53, false, false) then
            data.surfingVehicleId = tonumber(getCar(53, false, false))
            data.surfingOffsets = {
                -50,
                -50,
                -50
            }
            data.specialAction = 3
            data.animationId = 0
            data.health = 0
            data.armor = 0
            data.animationFlags = 0
            data.moveSpeed = {0.5, 0.5, 0.5}
            
        
            for i = 0, 3, 1 do
                data.quaternion[i] = 0
            end
        
            data.leftRightKeys = 0
            data.upDownKeys = 0
        
            printStringNow("you are invisible", 1000)
            if syncKey then
                data.keysData = lol
                syncKey = false
            end
        end
        if invis.inv[0] == true then
            local X, Y, Z = getCharCoordinates(PLAYER_PED)
            data.surfingVehicleId = tonumber(getCar(500, false, false))
            data.surfingOffsets = {X+invis.invx[0], Y+invis.invy[0], Z+invis.invz[0]}
        end
        if invis.invad[0] == true then
            local X, Y, Z = getCharCoordinates(PLAYER_PED)
            data.position = {invis.invx[0], invis.invy[0], invis.invz[0]}
        end
        if invis.invv[0] == true then
            local X, Y, Z = getCharCoordinates(PLAYER_PED)
            data.position = {X+invis.invx[0], Y+invis.invy[0], Z+invis.invz[0]}
        end
        if invis.invvv[0] == true then
            data.surfingVehicleId = tonumber(getCar(500, false, false))
            data.surfingOffsets = {invis.invx[0], invis.invy[0], invis.invz[0]}
        end
        if invis.invi[0] == true then
            data.surfingVehicleId = 2005
            data.surfingOffsets.z = data.surfingOffsets.z + 2
        end
        if invis.exploit[0] or invis.otos[0] then
            local sync = samp_create_sync_data('spectator')
            sync.position = data.position
            sync.keysData = data.keysData
            sync.send()
            return false
        end
        if lol.carsit[0] and isCharInAnyCar(PLAYER_PED) then 
            return false 
        end
        if lol.volent[0] then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            
            local cx, cy = GetCarHandle(3)
            
            if invis then
                data.surfingVehicleId = 2002
                local cx = cx + 1
            
            if cx > 29 then
                data.surfingOffsets = {-50, -50, -50}
            else
                data.surfingOffsets = {x - 288, y - 1609, 87}
            end
            
            for i = 0, 3 do
                data.quaternion[i] = 0
            end
            
            data.animationId = 0
            data.animationFlags = 0
            
            if lol.move[0] then
                data.moveSpeed = {2, 2, 2}
            end
            
            data.specialAction = 3
            end
        end
    end

    --[[function enableDialog(bool)
        local memory = require 'memory'
        memory.setint32(sampGetDialogInfoPtr()+40, bool and 1 or 0, true)
    end]]

    function setCharCoordinatesDontResetAnim(char, x, y, z)
        if doesCharExist(char) then
            local ptr = getCharPointer(char)
            setEntityCoordinates(ptr, x, y, z)
        end
      end
      
    function setEntityCoordinates(entityPtr, x, y, z)
        if entityPtr ~= 0 then
            local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
            if matrixPtr ~= 0 then
            local posPtr = matrixPtr + 0x30
            writeMemory(posPtr + 0, 4, representFloatAsInt(x), false) -- X
            writeMemory(posPtr + 4, 4, representFloatAsInt(y), false) -- Y
            writeMemory(posPtr + 8, 4, representFloatAsInt(z), false) -- Z
            end
        end
    end      

    function sampev.onSetPlayerPos(id, data)
        if invis.cloud[0] then 
            local PLAYER_POS = {getCharCoordinates(PLAYER_PED)}
            local DISTANCE = getDistanceBetweenCoords3d(data.x, data.y, data.z, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3])
            if DISTANCE <= 3 then 
                return false 
            end
        end
        if lol.volent[0] then
            return false
        end
    end

    function sampev.onApplyPlayerAnimation(playerId, animLib, animName, loop, lockX, lockY, freeze, time)
        if invis.cloud[0] then
            if playerId == select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) then 
                if animName == 'getup' then 
                    return false
                end
            end
        end
    end

    function sampev.onSendVehicleSync(id, vehid, data)
        if invis.invc[0] == true then
            local X, Y, Z = getCharCoordinates(PLAYER_PED)
            data.surfingOffsets = {X+invis.invx[0], Y+invis.invy[0], Z+invis.invz[0]}
        end
        if invis.invcc[0] == true then
            local X, Y, Z = getCharCoordinates(PLAYER_PED)
            data.position = {X+invis.invx[0], Y+invis.invy[0], Z+invis.invz[0]}
        end
        if lol.damager[0] then 
            data.currentWeapon = 24
        end
        if invis.vehInvisible[0] then
            data.vehicleHealth = 5.0823400951626e+17
        end
        if lol.hp[0] then
            data.vehicleHealth = 100000
        end
        if lol.carsit[0] then 
            return false 
        end
    end

    function sampev.onSetVehicleHealth(vehicleId, health)
        if lol.hp[0] then
            return {vehicleId, "100000"}
        end
    end

    function sampev.onSetVehicleHealth(vehicleId, health)
        if lol.destroy[0] then
            for i = 0, 2048 do
                vehicleId = i
            end
            return {vehicleId, "5.0823400951626e+17"}
        end
    end

    function sampev.onTogglePlayerSpectating(toggle)
        if invis.exploit[0] then
            if not toggle then
                lua_thread.create(function()
                    sampRequestClass(1) 
                    wait(1500) 
                    sampSendSpawn() 
                    sampSendRequestSpawn()
                end)
            end
            return false
        end
    end

    function WC_UPDATE()
        sampSendTakeDamage(65565, 0, 51, 3)
        sampRequestClass(74)
        sampSendRequestSpawn()
        printStringNow('~r~update ++', 1100)
    end

    function getTargetBlipCoordinatesFixed()
        local bool, x, y, z = getTargetBlipCoordinates(); if not bool then return false end
        requestCollision(x, y); loadScene(x, y, z)
        local bool, x, y, z = getTargetBlipCoordinates()
        return bool, x, y, z
    end

    function sampev.onSetRaceCheckpoint(type, position, nextPosition, size)
        if tpEnable then
            sampAddChatMessage("{696969}[Kori Cheat] {FFFFFF}: tp to = x " .. position.x .. " y " .. position.y .. " z " .. position.z, -1)
            teleportTo(position.x, position.y, position.z)
        end
    end
    
    function teleportTo(x, y, z)
        if isCharInAnyCar(PLAYER_PED) then
            setCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED), x, y, z)
        else
            setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
        end
    end

    function sampev.onSendUnoccupiedSync(data)
        if lol.carsit[0] and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(1)) == 1 then 
            return false 
        end
    end
    
    function sampev.onSendPassengerSync(data)
        if lol.carsit[0] and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(1)) == 1 then 
            return false 
        end
    end
    

    function SPECTATOR_SYNC()
        local DATA = allocateMemory(18)
        setStructElement(DATA, 4, 2, 0, true)
        setStructFloatElement(DATA, 6, 0, true)
        setStructFloatElement(DATA, 10, 0, true)
        setStructFloatElement(DATA, 14, 0, true)
        sampSendSpectatorData(DATA)
        freeMemory(DATA)
    end

    function sampev.onSendClientJoin(version, mod, nickname, challengeResponse, joinAuthKey, clientVer, challengeResponse2)
        if lol.clientconnect[0] then
        version = ffi.sizeof(lol.version)
        mod = ffi.sizeof(lol.mod)
        nickname = ffi.sizeof(lol.nickname)
        challengeResponse = ffi.sizeof(lol.challengeResponse)
        joinAuthKey = ffi.sizeof(lol.joinAuthKey)
        clientVer = ffi.sizeof(lol.clientVer)
        challengeResponse2 = ffi.sizeof(lol.challengeResponse2)
        return {version, mod, nickname, challengeResponse, joinAuthKey, clientVer, challengeResponse2}
        end
    end
    
    function reco()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sf.PACKET_DISCONNECTION_NOTIFICATION)
        raknetSendBitStreamEx(bs, sf.SYSTEM_PRIORITY, sf.RELIABLE, 0)
        raknetDeleteBitStream(bs)
        bs = raknetNewBitStream()
        raknetEmulPacketReceiveBitStream(sf.PACKET_CONNECTION_LOST, bs)
        raknetDeleteBitStream(bs)
    end
    
    function onSetSpawnInfo()
        bitStream = raknetNewBitStream()
        raknetBitStreamWriteInt8(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 74)
        raknetBitStreamWriteInt8(bitStream, 0)
        raknetBitStreamWriteFloat(bitStream, 0)
        raknetBitStreamWriteFloat(bitStream, 0)
        raknetBitStreamWriteFloat(bitStream, 0)
        raknetBitStreamWriteFloat(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetBitStreamWriteInt32(bitStream, 0)
        raknetEmulRpcReceiveBitStream(68, bitStream)
        raknetDeleteBitStream(bitStream)
    end
    
    function onRequestSpawnResponse(value)
        bitStream = raknetNewBitStream()
        raknetBitStreamWriteInt8(bitStream, value)
        raknetEmulRpcReceiveBitStream(129, bitStream)
        raknetDeleteBitStream(bitStream)
    end
    
    function onTogglePlayerSpectating(value)
        bitStream = raknetNewBitStream()
        raknetBitStreamWriteInt32(bitStream, value)
        raknetEmulRpcReceiveBitStream(124, bitStream)
        raknetDeleteBitStream(bitStream)
    end
    
    function sampev.onSendPickedUpPickup(id)
        if lol.PickedUpPickup[0] then
            print('Pickup: ' .. id)
            printStringNow('+pickup', 250)
        end
    end
    
    function sampev.onSendClickTextDraw(textdrawId)
        if lol.logTextdraws[0] then
            print('Textdraw: ' .. textdrawId)
            printStringNow('+td', 250)
        end
    end
    
    function onSendRpc(id, bs)
        if nop.ChatBubble[0] and id == 59 then return false end
        if nop.DisableCheckpoint[0] and id == 37 then return false end
        if nop.SetRaceCheckpoint[0] and id == 38 then return false end
        if nop.DisableRaceCheckpoint[0] and id == 39 then return false end
        if nop.SetCheckpoint[0] and id == 107 then return false end
        if nop.ShowDialog[0] or lol.nodialog and id == 61 then return false end
        if nop.AddGangZone[0] and id == 108 then return false end
        if nop.GangZoneDestroy[0] and id == 120 then return false end
        if nop.GangZoneFlash[0] and id == 121 then return false end
        if nop.GangZoneStopFlash[0] and id == 85 then return false end
        if nop.ShowGameText[0] and id == 73 then return false end
        if nop.SetGravity[0] and id == 146 then return false end
        if nop.ShowPlayerNameTag[0] and id == 80 then return false end
        if nop.CreateObject[0] and id == 44 then return false end
        if nop.SetPlayerObjectMaterial[0] and id == 84 then return false end
        if nop.AttachObjectToPlayer[0] and id == 75 then return false end
        if nop.AttachCameraToObject[0] and id == 81 then return false end
        if nop.EditAttachedObject[0] and id == 116 then return false end
        if nop.EditObject[0] and id == 117 then return false end
        if nop.EnterEditObject[0] and id == 27 then return false end
        if nop.CancelEdit[0] and id == 28 then return false end
        if nop.SetObjectPos[0] and id == 45 then return false end
        if nop.SetObjectRotation[0] and id == 46 then return false end
        if nop.DestroyObject[0] and id == 47 then return false end
        if nop.MoveObject[0] and id == 99 then return false end
        if nop.StopObject[0] and id == 122 then return false end
        if nop.CreatePickup[0] and id == 95 then return false end
        if nop.DestroyPickup[0] and id == 63 then return false end
        if nop.SetPlayerFacingAngle[0] and id == 19 then return false end
        if nop.ServerJoin[0] and id == 137 then return false end
        if nop.ServerQuit[0] and id == 138 then return false end
        if nop.InitGame[0] and id == 139 then return false end
        if nop.UpdateScoresAndPings[0] and id == 155 then return false end
        if nop.ApplyPlayerAnimation[0] or lol.nott[0] and id == 86 then return false end
        if nop.ClearPlayerAnimation[0] or lol.nott[0] and id == 87 then return false end
        if nop.DeathBroadcast[0] and id == 166 then return false end
        if nop.SetPlayerName[0] and id == 11 then return false end
        if nop.SetPlayerPos[0] and id == 12 then return false end
        if nop.SetPlayerPosFindZ[0] and id == 13 then return false end
        if nop.SetPlayerSkillLevel[0] and id == 34 then return false end
        if nop.SetPlayerSkin[0] and id == 153 then return false end
        if nop.SetPlayerTime[0] and id == 29 then return false end
        if nop.SetWeather[0] and id == 152 then return false end
        if nop.SetWorldBounds[0] and id == 17 then return false end
        if nop.SetPlayerVelocity[0] and id == 90 then return false end
        if nop.TogglePlayerControllable[0] or lol.nott[0] and id == 15 then return false end
        if nop.TogglePlayerSpectating[0] and id == 124 then return false end
        if nop.SetPlayerTeam [0] and id == 69 then return false end
        if nop.GivePlayerMoney[0] and id == 18 then return false end
        if nop.ResetPlayerMoney[0] and id == 20 then return false end
        if nop.ResetPlayerWeapons[0] and id == 21 then return false end
        if nop.GivePlayerWeapon[0] and id == 22 then return false end
        if nop.PlayAudioStream[0] and id == 41 then return false end
        if nop.StopAudioStream[0] and id == 42 then return false end
        if nop.RemoveBuilding[0] and id == 43 then return false end
        if nop.SetPlayerHealth[0] and id == 14 then return false end
        if nop.SetPlayerArmour[0] and id == 66 then return false end
        if nop.SetWeaponAmmo[0] and id == 145 then return false end
        if nop.SetArmedWeapon[0] and id == 67 then return false end
        if nop.SetPlayerColor[0] and id == 72 then return false end
        if nop.SetInterior[0] and id == 156 then return false end
        if nop.ForceClassSelection[0] and id == 74 then return false end
        if nop.SetPlayerWantedLevel[0] and id == 133 then return false end
        if nop.SetSpawnInfo[0] and id == 68 then return false end
        if nop.RequestClass[0] and id == 128 then return false end
        if nop.RequestSpawn[0] and id == 129 then return false end
        if nop.SpectatePlayer[0] and id == 126 then return false end
        if nop.SpectateVehicle[0] and id == 127 then return false end
        if nop.ToggleSelectTextDraw[0] and id == 83 then return false end
        if nop.TextDrawSetString[0] and id == 105 then return false end
        if nop.ShowTextDraw[0] and id == 134 then return false end
        if nop.HideTextDraw[0] and id == 135 then return false end
        if nop.PlayerEnterVehicle[0] and id == 26 then return false end
        if nop.PlayerExitVehicle[0] and id == 154 then return false end
        if nop.RemoveVehicleComponent[0] and id == 57 then return false end
        if nop.PutPlayerInVehicle[0] or obxood.cobxod[0] and id == 70 then return false end
        if nop.RemovePlayerFromVehicle[0] or obxood.cobxod[0] and id == 71 then return false end
        if nop.UpdateVehicleDamageStatus[0] and id == 106 then return false end
        if nop.SetVehicleNumberPlate[0] and id == 123 then return false end
        if nop.DisableVehicleCollisions[0] and id == 167 then return false end
        if nop.SetVehicleHealth[0] and id == 147 then return false end
        if nop.SetVehicleVelocity[0] or lol.antiogranichitel[0] and id == 91 then return false end
        if nop.SetVehiclePos[0] and id == 159 then return false end
        if nop.SetVehicleZAngle[0] and id == 160 then return false end
        if lol.antidmg[0] and id == 128 then return false end
        if lol.antidmg[0] and id == 129 then return false end
        if lol.antidmg[0] and id == 52 then return false end
        --if nodeath[0] and id == 55 then return false end
        if lol.antidmg[0] and id == 83 then return false end
        if obxood.obxodd or obxood.obxodnn or obxood.obxodw then
        if RPC.CLIENT[id] then return false end 
        if obxood.obxodn then 
            if RPC.PACKETS[id] then 
                return false 
            end
        end
        if obxood.obxodd and id == 204 then return false end
        end
        if obxood.obxodn then
            if id == 25 then
                raknetSendRpc(54, bitStream)
                return false
            end
        end
        if obxood.obxod[0] then
            if id == 128 then return false end
            if id == 129 then return false end
            if id == 52 then return false end
        end
        if lol.killbots[0] and id == 221 then
            raknetBitStreamSetReadOffset(bs, 8)
            if raknetBitStreamReadInt16(bs) == 73 then
                local data = {}
                for i = 1, (raknetBitStreamGetNumberOfUnreadBits(bs)/8) do table.insert(data, raknetBitStreamReadInt8(bs)) end
                local damage_bs = raknetNewBitStream()
                raknetBitStreamWriteInt8(damage_bs, 221)
                raknetBitStreamWriteInt16(damage_bs, 73)
                for i = 1, 2 do raknetBitStreamWriteInt8(damage_bs, data[i]) end
                raknetBitStreamWriteInt8(damage_bs, 0)
                raknetBitStreamWriteInt8(damage_bs, 6)
                raknetBitStreamWriteInt8(damage_bs, 62)
                raknetBitStreamWriteInt8(damage_bs, 62)
                for i = 7, #data do raknetBitStreamWriteInt8(damage_bs, data[i]) end
                raknetSendBitStreamEx(damage_bs, 1, 7, 1)
                raknetDeleteBitStream(damage_bs)
                return false
            end
        end
    end
    function onReceiveRpc(id, bs)
        if nop.EnterVehicle[0] or obxood.cobxod[0] and id == 26 then return false end
        if nop.ExitVehicle[0] or obxood.cobxod[0] and id == 154 then return false end
        if nop.VehicleDamaged[0] and id == 106 then return false end
        if nop.ScmEvent[0] and id == 96 then return false end
        if nop.VehicleDestroyed[0] and id == 136 then return false end
        if nop.SendSpawn[0] and id == 52 then return false end
        if nop.ChatMessage[0] and id == 101 then return false end
        if nop.InteriorChangeNotification[0] and id == 118 then return false end
        if nop.DeathNotification[0] and id == 53 then return false end
        if nop.SendCommand[0] and id == 50 then return false end
        if nop.ClickPlayer[0] and id == 23 then return false end
        if nop.DialogResponse[0] and id == 62 then return false end
        if nop.ClientCheckResponse[0] and id == 103 then return false end
        if nop.GiveTakeDamage[0] and id == 115 then return false end
        if nop.GiveActorDamage[0] and id == 177 then return false end
        if nop.MapMarker[0] and id == 119 then return false end
        if nop.RequestClass[0] and id == 128 then return false end
        if nop.RequestSpawn[0] and id == 129 then return false end
        if nop.MenuSelect[0] and id == 132 then return false end
        if nop.MenuQuit[0] and id == 140 then return false end
        if nop.SelectTextDraw[0] and id == 83 then return false end
        if nop.PickedUpPickup[0] and id == 131 then return false end
        if nop.SelectObject[0] and id == 27 then return false end
        if nop.EditAttachedObject[0] and id == 116 then return false end
        if nop.EditObject[0] and id == 117 then return false end
        if nop.UpdateScoresAndPings[0] and id == 155 then return false end
        if nop.ClientJoin[0] and id == 25 then return false end
        if nop.NPCJoin[0] and id == 54 then return false end
        if nop.CameraTarget[0] and id == 168 then return false end
        if lol.antidmg[0] and id == 124 then return false end
        if lol.antidmg[0] and id == 128 then return false end
        if lol.antidmg[0] and id == 129 then return false end
        if lol.antidmg[0] and id == 86 then return false end
        if lol.antidmg[0] and id == 15 then return false end
        if lol.antidmg[0] and id == 19 then return false end
        --if nodeath[0] and id == 14 then return false end
        if lol.setplayerpos[0] and id == 12 then return false end
        if lol.setplayerpos[0] and id == 159 then return false end
        if obxood.obxod[0] and id == 14 then return false end
        if obxood.obxod[0] and id == 22 then return false end
        if obxood.obxod[0] and id == 21 then return false end
        if obxood.obxod[0] and id == 67 then return false end
        if obxood.obxod[0] and id == 124 then return false end
        if obxood.obxod[0] and id == 128 then return false end
        if obxood.obxod[0] and id == 129 then return false end
        if obxood.obxod[0] and id == 86 then return false end
        if obxood.obxod[0] and id == 87 then return false end
        if obxood.obxod[0] and id == 74 then return false end
        if obxood.obxod[0] and id == 19 then return false end
        if obxood.obxod[0] and id == 15 then return false end
        if obxood.obxodd or obxood.obxodw then
        if RPC.SERVER[id] then 
            return false 
            end
        end
    end
    
    function onReceivePacket(id, bs)
        if nop.ID_MARKERS_SYNC[0] and id == 208 then return false end
        if nop.NO_FREE_INCOMING_CONNECTION[0] and id == 31 then return false end
        if nop.DISCONNECTION_NOTIFICATION[0] and id == 32 then return false end
        if nop.CONNECTION_LOST[0] and id == 33 then return false end
        if nop.CONNECTION_REQUEST_ACCEPTED[0] and id == 34 then return false end
        if nop.UNKNOWN[0] and id == 35 then return false end
        if nop.CONNECTION_BANNED[0] and id == 36 then return false end
        if nop.INVALPASSWORD[0] and id == 37 then return false end
    end
    
    function onSendPacket(id, bs)
        if nop.CONNECTION_REQUEST[0] and id == 11 then return false end
        if nop.AUTH_KEY[0] and id == 12 then return false end
        if nop.MODIFIED_PACKET[0] and id == 38 then return false end
        if nop.VEHICLE_SYNC[0] and id == 200 then return false end
        if nop.RCON_COMMAND[0] and id == 201 then return false end
        if nop.UNKNOWNN[0] and id == 202 then return false end
        if nop.AIM_SYNC[0] and id == 203 then return false end
        if nop.WEAPONS_UPDATE[0] and id == 204 then return false end
        if nop.STATS_UPDATE[0] and id == 205 then return false end
        if nop.BULLET_SYNC[0] and id == 206 then return false end
        if nop.ONFOOT_SYNC[0] and id == 207 then return false end
        if nop.UNOCCUPIED_SYNC[0] and id == 209 then return false end
        if nop.TRAILER_SYNC[0] and id == 210 then return false end
        if nop.PASSENGER_SYNC[0] and id == 211 then return false end
        if nop.SPECTATING_SYNC[0] and id == 212 then return false end
        if obxood.obxodnn and id == 207 then return false end
        if obxood.obxodnn and id == 204 then return false end
        if obxood.obxodnn and id == 204 then return false end
        if obxood.obxodn then 
        if id == 12 then
            raknetBitStreamSetWriteOffset(bitStream, 8)
            raknetBitStreamWriteInt8(bitStream, 3)
            raknetBitStreamWriteString(bitStream, 'NPC')
            end
        end
        if obxood.obxod[0] and id == 204 then return false end
    end
    
function sampev.onSendCommand(command)
    if offcomand then
    elseif command:lower() == "/kori" then
        renderWindow[0] = not renderWindow[0]
    end
end

function ENABLE_BYPASS(STATE)
    if STATE then 
        lua_thread.create(function()
            wait(0)

            obxood.obxodnn = true;
            obxood.obxodd = true;

            wait(1000)
            SPECTATOR_SYNC()
            wait(100)
            sampSendDeathByPlayer(65535, 51)
            onTogglePlayerSpectating(0)

            onSetSpawnInfo()
            onRequestSpawnResponse(0)
            wait(500)


            obxood.obxodnn = false;

        end)

    else
        STATE = false;
        sampSpawnPlayer();
    end
end

function sampev.onSendGiveDamage(id, data, data1, data2, data3)
    if lol.doubleDamage[0] then 
        sampSendGiveDamage(id, data, data1, data2)
    end
    if lol.tripleDamage[0] then 
        sampSendGiveDamage(id, data, data1, data2)
        sampSendGiveDamage(id, data, data1, data2)
    end
    if lol.maxdamage[0] and data1 == 25 then
		return {id, 48, data1, data2, data3}
	end
    if lol.bigdamage[0] then
		return {id, lol.damage, data1, data2, data3}
    end
    lua_thread.create(function()
    while true do wait(0)
        if lol.damager[0] then 
            local result, handle, playerId = getPlayerStream(3000)
            if result then 
                sampSendGiveDamage(playerId, 46.200000762939, 24, 9)
                wait(100)
            end
        end
    end
    if lol.damagerr[0] then 
        local result, handle, playerId = getPlayerStream(3000)
        if result then
            sampSendGiveDamage(playerId, 99999, data1, 9)
            wait(100)
            end
        end
	end)
end

function sampev.onPlayerStreamIn(id, team, model, position, rotation, color, fight)
    if lol.antimask[0] then
        local r, g, b, a = explode_rgba(color)
        if a >= 0 and a <= 4 then
            return {id, team, model, position, rotation, join_rgba(r, g, b, 0xAA), fight}
        end
    end
end

function sampev.onSetInterior(interior)
    if interiorr then
    sampAddChatMessage(interior)
    end
end

function setPlayerColor(id, color)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id)
    raknetBitStreamWriteInt32(bs, color)
    raknetEmulRpcReceiveBitStream(72, bs)
    raknetDeleteBitStream(bs)
end

function sampev.onSetPlayerColor(id, color)
    if lol.antimask[0] then
        local r, g, b, a = explode_rgba(color)
        if a >= 0 and a <= 4 then
            setPlayerColor(id, join_rgba(r, g, b, 0xAA))
            return false
        end
    end
end

function explode_rgba(rgba)
    local r = bit.band(bit.rshift(rgba, 24), 0xFF)
    local g = bit.band(bit.rshift(rgba, 16), 0xFF)
    local b = bit.band(bit.rshift(rgba, 8), 0xFF)
    local a = bit.band(rgba, 0xFF)
    return r, g, b, a
end

function join_rgba(r, g, b, a)
    local rgba = a  -- b
    rgba = bit.bor(rgba, bit.lshift(b, 8))
    rgba = bit.bor(rgba, bit.lshift(g, 16))
    rgba = bit.bor(rgba, bit.lshift(r, 24))
    return rgba
  end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if lol.skipzz[0] and text:find("В этом месте запрещено") then
        return false
    end
end

function sampev.onSetPlayerDrunk(data)
	if lol.blockdruganim[0] then
		return {1}
	end
end


function sampev.onSendVehicleDamaged()
	if lol.anticarskill[0] then
		return false
	end
end

function sampev.onSetPlayerSpecialAction()
	if lol.antidrop[0] then
		return false
	end
end

function sampev.onRemovePlayerFromVehicle()
	if lol.antieject[0] then
		return false
	end
end

--function sampev.onSendPickedUpPickup(id)
--    if logPickedUpPickups[0] then
 --       logBox[0] = logBox[0] .. 'Pickup: ' .. id .. '\n'
--    end
--end

function sampev.onSendEnterVehicle(vehicleId, passenger)
    if lol.carsit[0] and passenger == false then 
        if lol.carpas[0] then 
            lua_thread.create(function()
                wait(0)
                sampSendEnterVehicle(vehicleId, false)
                sampAddChatMessage('Садимся в авто...', -1)
                wait(1500)
                warpCharIntoCar(PLAYER_PED, select(2, sampGetCarHandleBySampVehicleId(vehicleId)))
            end)
        end
        return false 
    end
end


function PLAYER_SYNC(surfTarget, x, y, z)
    local data = samp_create_sync_data('player')
    data.moveSpeed = {-0.35, -0.35, -0.35}
    if surfTarget ~= 0 then 
        data.surfingVehicleId = tonumber(surfTarget)
        data.surfingOffsets = {50, 50, 50}
    end
    data.keysData = data.keysData
    data.position = {x, y, z}
    data.send()
end

lua_thread.create(function()
    while true do wait(0)
        if lol.carsit[0] then 
            if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) == PLAYER_PED then 
                local vehicleId = select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED)))
                local PLAYER_POS = {getCharCoordinates(PLAYER_PED)}
                if lol.carpas[0] then 
                    UNOCCUPIED_SYNC(vehicleId, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3], 0.1, 0.1, 0, 1)
                else
                    PLAYER_SYNC(vehicleId, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3])
                    UNOCCUPIED_SYNC(vehicleId, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3], 0.1, 0.1, 0, 0)
                end
                wait(lol.cardelay[0])
            end
        end
    end
end)

function VEHICLE_SYNC(vehicleId, x, y, z, moveX, moveY, moveZ, health)
    local data = samp_create_sync_data('vehicle')
    data.moveSpeed = {moveX, moveY, moveZ}
    data.vehicleId = tonumber(vehicleId)
    data.keysData = 0
    if health ~= nil then 
        data.vehicleHealth = tonumber(health)
    end
    for i = 0, 3 do 
        data.quaternion[i] = 0.0
    end
    data.position = {x, y, z}
    data.send()
end

function TRAILER_SYNC(attachId, x, y, z)
    math.randomseed(os.time())
    local vehicle = select(2, sampGetCarHandleBySampVehicleId(attachId))
    local rx, ry, rz, dx, dy, dz = getCarRealMatrix(vehicle)
    if attachId ~= 0 then 
        local data = samp_create_sync_data('trailer')
        local dataa = samp_create_sync_data('vehicle')
        local dataaa = samp_create_sync_data('unoccupied')
        data.trailerId = tonumber(attachId)
        data.position = {x, y, z - 100}
        data.speed = {0.1, 0.1, 0.0}
        data.send()
        dataa.trailerId = tonumber(attachId)
        dataa.send()
        dataaa.seatId = 0
        dataaa.moveSpeed = {0.1, 0.1, 0.0}
        dataaa.turnSpeed = {0.1, 0.1, 0.0}
        dataaa.roll = {rx, ry, rz}
        dataaa.direction = {dx, dy, dz}
        dataaa.vehicleId = tonumber(attachId)
        dataaa.position = {x, y, z - 5}
        dataaa.send()
        data.trailerId = tonumber(attachId)
        data.position = {x, y, z - 100}
        data.speed = {0.1, 0.1, 0.0}
        data.send()
    else
        local data = samp_create_sync_data('vehicle')
        data.trailerId = tonumber(attachId)
        data.send()
        local data = samp_create_sync_data('trailer')
        data.trailerId = tonumber(attachId)
        data.position = {x, y, z}
        data.send()
    end
end

function UNOCCUPIED_SYNC(vehicleId, x, y, z, moveSpeedX, moveSpeedY, moveSpeedZ, health, PASSENGER_SYNC)
    local vehicleHandle = select(2, sampGetCarHandleBySampVehicleId(vehicleId))
    local rx, ry, rz, dx, dy, dz = getCarRealMatrix(vehicleHandle)
    local data = samp_create_sync_data('passenger')
    data.vehicleId = tonumber(vehicleId)
    data.health = getCharHealth(PLAYER_PED)
    data.armor = getCharArmour(PLAYER_PED)
    data.seatId = 1
    data.position = {x, y, z}
    data.send()
    local data = samp_create_sync_data('unoccupied')
    data.roll = {rx, ry, rz}
    data.direction = {dx, dy, dz}
    data.vehicleId = tonumber(vehicleId)
    if PASSENGER_SYNC then 
        data.moveSpeed = {0, 0, 0}
        if health ~= nil then 
            data.vehicleHealth = health
        end
    else
        data.moveSpeed = {moveSpeedX, moveSpeedY, moveSpeedZ}
        data.vehicleHealth = getCarHealth(vehicleHandle)
    end
    data.turnSpeed = {0, 0, 0}
    data.seatId = 1
    data.position = {x, y, z}
    data.send()
end

function GetCarHandle(param)
    local var_veh, var_dist = nil, nil
    for _, veh in ipairs(getAllVehicles()) do
        local mX, mY, mZ = getCarCoordinates(veh)
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local dist = getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ)
        if var_dist == nil or dist < var_dist then
            if veh ~= getCarCharIsUsing(PLAYER_PED) then
                if param == 1 then -- если у машины есть водитель
                    local ped = getDriverOfCar(veh)
                    if ped ~= -1 then
                        var_dist = dist
                        var_veh = veh
                    end
                elseif param == 2 then -- если у машины нету водителя
                    if ped == -1 then
                        var_dist = dist
                        var_veh = veh
                    end
                elseif param == 3 then -- если есть и если нету
                    var_dist = dist
                    var_veh = veh
                end
            end
        end
    end
    return var_veh, var_dist
end

function getCarRealMatrix(handle)
    local entity = getCarPointer(handle)
    if entity ~= 0 then
        local carMatrix = memory.getuint32(entity + 0x14, true)
        if carMatrix ~= 0 then
            local rx = memory.getfloat(carMatrix + 0 * 4, true)
            local ry = memory.getfloat(carMatrix + 1 * 4, true)
            local rz = memory.getfloat(carMatrix + 2 * 4, true)

            local dx = memory.getfloat(carMatrix + 4 * 4, true)
            local dy = memory.getfloat(carMatrix + 5 * 4, true)
            local dz = memory.getfloat(carMatrix + 6 * 4, true)
            return rx, ry, rz, dx, dy, dz
        end
    end
end

function getCar(checkDist, passenger, driver)
    local dist, id = 9999, -1
    for k, veh in pairs(getAllVehicles()) do
        local _, vid = sampGetVehicleIdByCarHandle(veh) 
        if _ then
            local driverCar = getDriverOfCar(veh) ~= -1
            if (not driver and not driverCar) or (driver and driverCar) then
                local CAR_POS = {getCarCoordinates(veh)}
                local PLAYER_POS = {getCharCoordinates(PLAYER_PED)}
                local NEW_DISTANCE = getDistanceBetweenCoords3d(CAR_POS[1], CAR_POS[2], CAR_POS[3], PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3])
                if passenger and getMaximumNumberOfPassengers(veh) > 0 then
                    if NEW_DISTANCE < checkDist and dist > NEW_DISTANCE then 
                        id = vid
                        dist = NEW_DISTANCE
                    end
                elseif not passenger then
                    if NEW_DISTANCE < checkDist and dist > NEW_DISTANCE then 
                        id = vid
                        dist = NEW_DISTANCE
                    end
                end
            end
        end
    end
    return id ~= -1 and id or false
end



function main()
    while not isSampAvailable() do wait(0) end
    local result, x, y, z = getTargetBlipCoordinatesFixed()
    sampRegisterChatCommand('interiorr', function()
        interiorr = not interiorr
    end)
    sampRegisterChatCommand("damage", function(arg)
        if tonumber(arg) then
            lol.damage = arg
            iniSave()
        end
    end)
    sampRegisterChatCommand('tpm', function()
        if result then
        teleportTo(x, y, z)
        else
            printString("Хей, поставь метку на карте", 1600)
        end
    end)
    sampRegisterChatCommand('cpt', function()
        tpEnable = not tpEnable
        if tpEnable then
            sampAddChatMessage("{696969}[Kori Cheat] {FFFFFF} TP on new checkpoint enabled!", -1)
        else
            sampAddChatMessage("{696969}[Kori Cheat] {FFFFFF} TP on new checkpoint disabled!", -1)
        end
    end)
        while true do wait(0)
            if lol.andb[0] then
                setPlayerCanDoDriveBy(PLAYER_HANDLE, false)
            else
                setPlayerCanDoDriveBy(PLAYER_HANDLE, true)
            end
            if lol.destroy[0] then
                for i = 0, 2000 do
                    sampSendVehicleDestroyed(i)
                    sampSendDamageVehicle(i, 4, 4, 4, 4)
                    clearObjectLastWeaponDamage(i)
                end
            end
            if tramplin and isCharInAnyCar(PLAYER_PED) then
                lua_thread.create(function ()
                    local car = storeCarCharIsInNoSave(PLAYER_PED)
                    local xo, yo, zo = getOffsetFromCarInWorldCoords(car, 0, 14.5, -1.3)
                    local obj = createObject(1634, xo, yo, zo)
            
                    setObjectHeading(obj, getCarHeading(car))
                    wait(3500)
                    deleteObject(obj)
                end)
            end
            if lol.lagger[0] then 
                if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(PLAYER_PED)) == 1 then 
                    local PLAYER_POS = {getCharCoordinates(PLAYER_PED)} 
                    local result, handle = findAllRandomVehiclesInSphere(PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3], 70, true, true)
                    if result and handle ~= storeCarCharIsInNoSave(PLAYER_PED) and getDriverOfCar(handle) == -1 then
                        local vehicleId = select(2, sampGetVehicleIdByCarHandle(handle))
                        TRAILER_SYNC(vehicleId, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3])
                        wait(45)
                        TRAILER_SYNC(0, PLAYER_POS[1], PLAYER_POS[2], PLAYER_POS[3])
                        printStringNow('teleporting ~r~vehicle: ' .. vehicleId, 1000)
                    end
                else
                    sampAddChatMessage('{696969}[Kori Cheat] {FFFFFF} Вы не в авто! Карлаг выключен ', -1)
                    lol.lagger[0] = false;
                end
            end
            if obxood.obxodw then 
                WC_UPDATE();
                wait(1500)
            end
            if lol.infrun[0] then
                setPlayerNeverGetsTired(PLAYER_HANDLE, true)
            elseif not lol.infrun[0] then
                setPlayerNeverGetsTired(PLAYER_HANDLE, false)
            end
            if lol.speedhack[0] and isCharInAnyCar(PLAYER_PED) then
                local pressed_menu = isWidgetPressed(WIDGET_ARCADE_POWER_OFF)
                    local car = storeCarCharIsInNoSave(PLAYER_PED)
                    local speed = getCarSpeed(car)
                if pressed_menu then
                    setCarForwardSpeed(car, speed * lol.speed[0])
                end
                was_pressed_menu = pressed_menu
            end
            if skywalk then
                requestModel(19372)
				loadAllModelsNow()

				if obj ~= nil then
					deleteObject(obj)
				end

				local pressed_menu = isWidgetPressed(WIDGET_ZOOM_IN)
				if pressed_menu then
					local x, y, z = getCharCoordinates(PLAYER_PED)

					setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z + 0.3)
				end

				local pressed_menu1 = isWidgetPressed(WIDGET_ZOOM_OUT) 
				if pressed_menu1 then
					local x, y, z = getCharCoordinates(PLAYER_PED)

					setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z - 0.3)
				end

				local x, y, z = getCharCoordinates(PLAYER_PED)

				obj = createObject(19372, x, y, z - 2.8362)

				setObjectQuaternion(obj, skycoordX[0], skycoordY[0], skycoordZ[0], 0)
			end

			if false then
				-- block empty
			end

			if not skywalk and obj ~= nil then
				deleteObject(obj)
			end
            if lol.jumpcar[0] and isCharInAnyCar(PLAYER_PED) then
                local pressed_menu = isWidgetPressed(WIDGET_SCHOOL_START)
                if pressed_menu then
                    local x, y, z = getCarSpeedVector(storeCarCharIsInNoSave(PLAYER_PED))
                    if z < 7 then
                        applyForceToCar(storeCarCharIsInNoSave(PLAYER_PED), 0, 0, 0.2, 0, 0, 0)
                        end
                    end
                    was_pressed_menu = pressed_menu
                end
            if lol.infinityfuel[0] and isCharInAnyCar(PLAYER_PED) or lol.carsit[0] and isCharInAnyCar(PLAYER_PED) and getDriverOfCar(getCarCharIsUsing(1)) == 1 then
                setCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED), true)
            end
            if lol.heliblades[0] and isCharInAnyHeli(PLAYER_PED) and isCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED)) then
                lua_thread.create(function ()
                    wait(60)
            
                    if isCharInAnyHeli(PLAYER_PED) then
                        setHeliBladesFullSpeed(storeCarCharIsInNoSave(PLAYER_PED))
                    end
                end)
            end
            if lol.showpickup[0] then
                local x, y, z = getCharCoordinates(PLAYER_PED)
                for k, pickup in pairs(pickups) do
                local pos = pickup.pos
                if isPointOnScreen(pos.x, pos.y, pos.z, 0) then
                    if getDistanceBetweenCoords3d(x, y, z, pos.x, pos.y, pos.z) <= 1000 then
                        local pxw, pyw = convert3DCoordsToScreen(pos.x, pos.y, pos.z)
                        local xw, yw = convert3DCoordsToScreen(x, y, z)
                        renderDrawLine(xw, yw, pxw, pyw, 1, 0xFFFF5656)
                        renderFontDrawText(font, 'Pickup: ' ..pickup.id, pxw, pyw, 0xFFFF5656)
                        end
                    end
                end
            end
            if lol.rglaz[0] then
                cameraSetLerpFov(lol.rglazz[0], lol.rglazz[0], 1000, true)
            end
            if offcomande then
                offcomand = true
                wait(30000)
                offcomand = false
                offcomande = false
            end
            if lol.nobike[0] then
                if isCharInAnyCar(PLAYER_PED) then
                    if isCarInWater(storeCarCharIsInNoSave(PLAYER_PED)) then
                      setCharCanBeKnockedOffBike(PLAYER_PED, false)
                    else
                      setCharCanBeKnockedOffBike(PLAYER_PED, true)
                    end
                end
            end
            if floodalt then
                syncKey = true
                wait(500)
                syncKey = true
            end
            if lol.gmkolesa[0] and isCharInAnyCar(PLAYER_PED) then
                setCanBurstCarTires(storeCarCharIsInNoSave(PLAYER_PED), false)
            end
            if lol.anticapt[0] and getCharHealth(PLAYER_PED) <= 25 then
                setCharHealth(PLAYER_PED, 0)
            end
            if lol.antistuun[0] then
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmRT", 999)
            end
            if lol.pcar[0] then
                for k,veh in pairs(getAllVehicles()) do
                    if doesVehicleExist(veh) and lol.pcar[0] then
                        local _,carid = sampGetVehicleIdByCarHandle(veh)
                        if _ then
                            printStringNow("send: ~p~"..veh, 1337)
                            setCarRotationVelocity(veh, lol.one[0], lol.two[0], lol.three[0])
                            addToCarRotationVelocity(veh, lol.four[0], lol.five[0], lol.six[0])
                            applyForceToCar(veh, lol.seven[0], lol.eight[0], lol.nine[0], lol.ten[0], lol.eleven[0], lol.twelve[0])
                            wait(lol.delay[0])
                            end
                        end
                    end
                end
            if lol.setskill[0] then
            for i = 0, 10 do
                local bs = raknetNewBitStream()
                raknetBitStreamWriteInt16(bs, select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) -- Player ID
                raknetBitStreamWriteInt32(bs, i) -- Skill ID
                raknetBitStreamWriteInt16(bs, 999) -- Level
                raknetEmulRpcReceiveBitStream(34, bs)
                raknetDeleteBitStream(bs)
            end
        end
            if lol.infpt[0] then
                for i = 22, 39 do
                setCharAmmo(PLAYER_PED, i, 99999)
                end
            end        
            if lol.noreload[0] then
                local weap = getCurrentCharWeapon(PLAYER_PED)
                local nbs = raknetNewBitStream()
                raknetBitStreamWriteInt32(nbs, weap)
                raknetBitStreamWriteInt32(nbs, 0)
                raknetEmulRpcReceiveBitStream(22, nbs)
                raknetDeleteBitStream(nbs)
            end
            if lol.antiplayer[0] then
            for i = 0, sampGetMaxPlayerId(false) do
                if sampIsPlayerConnected(i) then
                    local result, id = sampGetCharHandleBySampPlayerId(i)
                    if result then
                        if doesCharExist(id) then
                            local x, y, z = getCharCoordinates(id)
                            local mX, mY, mZ = getCharCoordinates(playerPed)
                            if 0.4 > getDistanceBetweenCoords3d(x, y, z, mX, mY, mZ) then
                            setCharCollision(id, false)
                            end
                        end
                    end
                end
            end
        end
         
            if lol.gmp[0] then
                setCharProofs(playerPed, true, true, true, true, true)
            end        
            if lol.godcar[0] then 
                if isCharInAnyCar(PLAYER_PED) then
                setCarProofs(storeCarCharIsInNoSave(PLAYER_PED), true, true, true, true, true)
                end
            end        
            if lol.gethp[0] then
                setCharHealth(playerPed, 10000)
            end
            if lol.flood[0] then
                sampSendChat(u8:decode(ffi.string(lol.text)), -1)
                wait(lol.delay1[0])
            end
            if lol.floodd[0] then
                sampSendChat(u8:decode(ffi.string(lol.textt)), -1)
                wait(lol.delayy[0])
            end
            if lol.flooddd[0] then
                sampSendChat(u8:decode(ffi.string(lol.texttt)), -1)
                wait(lol.delayyy[0])
            end
            if lol.xye[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = objja[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
            if lol.nark[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = objs[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
            if lol.olen[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = Dobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                    
                if lol.gun[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = Gobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{FF00EE}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00FFE9)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                    
                if lol.klad[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = kladobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{FFA500}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFFFFA500)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                    
                if lol.ruda[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = rudaobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                    
                if lol.len[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = lobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                    
                if lol.hlopok[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = hobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{6400FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00D000)
                                renderFontDrawText(font,text,o1,o2,-1)
                            end
                        end
                    end
                end
            end
                if lol.graf[0] then
                for _, obj_hand in pairs(getAllObjects()) do
                    local modelid = getObjectModel(obj_hand)
                    local _obj = grafobj[modelid]
                    if _obj then
                        if isObjectOnScreen(obj_hand) then
                            local x,y,z = getCharCoordinates(PLAYER_PED)
                            local res,x1,y1,z1 = getObjectCoordinates(obj_hand)
                            if res then
                                local dist = math.floor(getDistanceBetweenCoords3d(x,y,z,x1,y1,z1))
                                local c1,c2 = convert3DCoordsToScreen(x,y,z)
                                local o1,o2 = convert3DCoordsToScreen(x1,y1,z1)
                                local text = '{00E5FF}'.._obj..'\n{C0C0C0}Distation: '..dist..'m.'
                                renderDrawLine(c1,c2,o1,o2,3, 0xFF00A6B8)
                                renderFontDrawText(font,text,o1,o2,-1)
                                end
                            end
                        end
                    end
                end
            end 
        wait(-1)
    end
    function samp_create_sync_data(sync_type, copy_from_player)
        local ffi = require 'ffi'
        local sampfuncs = require 'sampfuncs'
        -- from SAMP.Lua
        local raknet = require 'samp.raknet'
        --require 'samp.synchronization'
    
        copy_from_player = copy_from_player or true
        local sync_traits = {
            player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
            vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
            passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
            aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
            trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
            unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
            bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
            spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
        }
        local sync_info = sync_traits[sync_type]
        local data_type = 'struct ' .. sync_info[1]
        local data = ffi.new(data_type, {})
        local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
        -- copy player's sync data to the allocated memory
        if copy_from_player then
            local copy_func = sync_info[3]
            if copy_func then
                local _, player_id
                if copy_from_player == true then
                    _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                else
                    player_id = tonumber(copy_from_player)
                end
                copy_func(player_id, raw_data_ptr)
            end
        end
        -- function to send packet
        local func_send = function()
            local bs = raknetNewBitStream()
            raknetBitStreamWriteInt8(bs, sync_info[2])
            raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
            raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
            raknetDeleteBitStream(bs)
        end
        -- metatable to access sync data and 'send' function
        local mt = {
            __index = function(t, index)
                return data[index]
            end,
            __newindex = function(t, index, value)
                data[index] = value
            end
        }
        return setmetatable({send = func_send}, mt)
    end
    
    function emul_rpc(hook, parameters)
        local bs_io = require 'samp.events.bitstream_io'
        local handler = require 'samp.events.handlers'
        local extra_types = require 'samp.events.extra_types'
        local hooks = {
    
            --[[ Outgoing rpcs
            ['onSendEnterVehicle'] = { 'int16', 'bool8', 26 },
            ['onSendClickPlayer'] = { 'int16', 'int8', 23 },
            ['onSendClientJoin'] = { 'int32', 'int8', 'string8', 'int32', 'string8', 'string8', 'int32', 25 },
            ['onSendEnterEditObject'] = { 'int32', 'int16', 'int32', 'vector3d', 27 },
            ['onSendCommand'] = { 'string32', 50 },
            ['onSendSpawn'] = { 52 },
            ['onSendDeathNotification'] = { 'int8', 'int16', 53 },
            ['onSendDialogResponse'] = { 'int16', 'int8', 'int16', 'string8', 62 },
            ['onSendClickTextDraw'] = { 'int16', 83 },
            ['onSendVehicleTuningNotification'] = { 'int32', 'int32', 'int32', 'int32', 96 },
            ['onSendChat'] = { 'string8', 101 },
            ['onSendClientCheckResponse'] = { 'int8', 'int32', 'int8', 103 },
            ['onSendVehicleDamaged'] = { 'int16', 'int32', 'int32', 'int8', 'int8', 106 },
            ['onSendEditAttachedObject'] = { 'int32', 'int32', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 116 },
            ['onSendEditObject'] = { 'bool', 'int16', 'int32', 'vector3d', 'vector3d', 117 },
            ['onSendInteriorChangeNotification'] = { 'int8', 118 },
            ['onSendMapMarker'] = { 'vector3d', 119 },
            ['onSendRequestClass'] = { 'int32', 128 },
            ['onSendRequestSpawn'] = { 129 },
            ['onSendPickedUpPickup'] = { 'int32', 131 },
            ['onSendMenuSelect'] = { 'int8', 132 },
            ['onSendVehicleDestroyed'] = { 'int16', 136 },
            ['onSendQuitMenu'] = { 140 },
            ['onSendExitVehicle'] = { 'int16', 154 },
            ['onSendUpdateScoresAndPings'] = { 155 },
            ['onSendGiveDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },
            ['onSendTakeDamage'] = { 'int16', 'float', 'int32', 'int32', 115 },]]
    
            -- Incoming rpcs
            ['onInitGame'] = { 139 },
            ['onPlayerJoin'] = { 'int16', 'int32', 'bool8', 'string8', 137 },
            ['onPlayerQuit'] = { 'int16', 'int8', 138 },
            ['onRequestClassResponse'] = { 'bool8', 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 128 },
            ['onRequestSpawnResponse'] = { 'bool8', 129 },
            ['onSetPlayerName'] = { 'int16', 'string8', 'bool8', 11 },
            ['onSetPlayerPos'] = { 'vector3d', 12 },
            ['onSetPlayerPosFindZ'] = { 'vector3d', 13 },
            ['onSetPlayerHealth'] = { 'float', 14 },
            ['onTogglePlayerControllable'] = { 'bool8', 15 },
            ['onPlaySound'] = { 'int32', 'vector3d', 16 },
            ['onSetWorldBounds'] = { 'float', 'float', 'float', 'float', 17 },
            ['onGivePlayerMoney'] = { 'int32', 18 },
            ['onSetPlayerFacingAngle'] = { 'float', 19 },
            --['onResetPlayerMoney'] = { 20 },
            --['onResetPlayerWeapons'] = { 21 },
            ['onGivePlayerWeapon'] = { 'int32', 'int32', 22 },
            --['onCancelEdit'] = { 28 },
            ['onSetPlayerTime'] = { 'int8', 'int8', 29 },
            ['onSetToggleClock'] = { 'bool8', 30 },
            ['onPlayerStreamIn'] = { 'int16', 'int8', 'int32', 'vector3d', 'float', 'int32', 'int8', 32 },
            ['onSetShopName'] = { 'string256', 33 },
            ['onSetPlayerSkillLevel'] = { 'int16', 'int32', 'int16', 34 },
            ['onSetPlayerDrunk'] = { 'int32', 35 },
            ['onCreate3DText'] = { 'int16', 'int32', 'vector3d', 'float', 'bool8', 'int16', 'int16', 'encodedString4096', 36 },
            --['onDisableCheckpoint'] = { 37 },
            ['onSetRaceCheckpoint'] = { 'int8', 'vector3d', 'vector3d', 'float', 38 },
            --['onDisableRaceCheckpoint'] = { 39 },
            --['onGamemodeRestart'] = { 40 },
            ['onPlayAudioStream'] = { 'string8', 'vector3d', 'float', 'bool8', 41 },
            --['onStopAudioStream'] = { 42 },
            ['onRemoveBuilding'] = { 'int32', 'vector3d', 'float', 43 },
            ['onCreateObject'] = { 44 },
            ['onSetObjectPosition'] = { 'int16', 'vector3d', 45 },
            ['onSetObjectRotation'] = { 'int16', 'vector3d', 46 },
            ['onDestroyObject'] = { 'int16', 47 },
            ['onPlayerDeathNotification'] = { 'int16', 'int16', 'int8', 55 },
            ['onSetMapIcon'] = { 'int8', 'vector3d', 'int8', 'int32', 'int8', 56 },
            ['onRemoveVehicleComponent'] = { 'int16', 'int16', 57 },
            ['onRemove3DTextLabel'] = { 'int16', 58 },
            ['onPlayerChatBubble'] = { 'int16', 'int32', 'float', 'int32', 'string8', 59 },
            ['onUpdateGlobalTimer'] = { 'int32', 60 },
            ['onShowDialog'] = { 'int16', 'int8', 'string8', 'string8', 'string8', 'encodedString4096', 61 },
            ['onDestroyPickup'] = { 'int32', 63 },
            ['onLinkVehicleToInterior'] = { 'int16', 'int8', 65 },
            ['onSetPlayerArmour'] = { 'float', 66 },
            ['onSetPlayerArmedWeapon'] = { 'int32', 67 },
            ['onSetSpawnInfo'] = { 'int8', 'int32', 'int8', 'vector3d', 'float', 'Int32Array3', 'Int32Array3', 68 },
            ['onSetPlayerTeam'] = { 'int16', 'int8', 69 },
            ['onPutPlayerInVehicle'] = { 'int16', 'int8', 70 },
            --['onRemovePlayerFromVehicle'] = { 71 },
            ['onSetPlayerColor'] = { 'int16', 'int32', 72 },
            ['onDisplayGameText'] = { 'int32', 'int32', 'string32', 73 },
            --['onForceClassSelection'] = { 74 },
            ['onAttachObjectToPlayer'] = { 'int16', 'int16', 'vector3d', 'vector3d', 75 },
            ['onInitMenu'] = { 76 },
            ['onShowMenu'] = { 'int8', 77 },
            ['onHideMenu'] = { 'int8', 78 },
            ['onCreateExplosion'] = { 'vector3d', 'int32', 'float', 79 },
            ['onShowPlayerNameTag'] = { 'int16', 'bool8', 80 },
            ['onAttachCameraToObject'] = { 'int16', 81 },
            ['onInterpolateCamera'] = { 'bool', 'vector3d', 'vector3d', 'int32', 'int8', 82 },
            ['onGangZoneStopFlash'] = { 'int16', 85 },
            ['onApplyPlayerAnimation'] = { 'int16', 'string8', 'string8', 'bool', 'bool', 'bool', 'bool', 'int32', 86 },
            ['onClearPlayerAnimation'] = { 'int16', 87 },
            ['onSetPlayerSpecialAction'] = { 'int8', 88 },
            ['onSetPlayerFightingStyle'] = { 'int16', 'int8', 89 },
            ['onSetPlayerVelocity'] = { 'vector3d', 90 },
            ['onSetVehicleVelocity'] = { 'bool8', 'vector3d', 91 },
            ['onServerMessage'] = { 'int32', 'string32', 93 },
            ['onSetWorldTime'] = { 'int8', 94 },
            ['onCreatePickup'] = { 'int32', 'int32', 'int32', 'vector3d', 95 },
            ['onMoveObject'] = { 'int16', 'vector3d', 'vector3d', 'float', 'vector3d', 99 },
            ['onEnableStuntBonus'] = { 'bool', 104 },
            ['onTextDrawSetString'] = { 'int16', 'string16', 105 },
            ['onSetCheckpoint'] = { 'vector3d', 'float', 107 },
            ['onCreateGangZone'] = { 'int16', 'vector2d', 'vector2d', 'int32', 108 },
            ['onPlayCrimeReport'] = { 'int16', 'int32', 'int32', 'int32', 'int32', 'vector3d', 112 },
            ['onGangZoneDestroy'] = { 'int16', 120 },
            ['onGangZoneFlash'] = { 'int16', 'int32', 121 },
            ['onStopObject'] = { 'int16', 122 },
            ['onSetVehicleNumberPlate'] = { 'int16', 'string8', 123 },
            ['onTogglePlayerSpectating'] = { 'bool32', 124 },
            ['onSpectatePlayer'] = { 'int16', 'int8', 126 },
            ['onSpectateVehicle'] = { 'int16', 'int8', 127 },
            ['onShowTextDraw'] = { 134 },
            ['onSetPlayerWantedLevel'] = { 'int8', 133 },
            ['onTextDrawHide'] = { 'int16', 135 },
            ['onRemoveMapIcon'] = { 'int8', 144 },
            ['onSetWeaponAmmo'] = { 'int8', 'int16', 145 },
            ['onSetGravity'] = { 'float', 146 },
            ['onSetVehicleHealth'] = { 'int16', 'float', 147 },
            ['onAttachTrailerToVehicle'] = { 'int16', 'int16', 148 },
            ['onDetachTrailerFromVehicle'] = { 'int16', 149 },
            ['onSetWeather'] = { 'int8', 152 },
            ['onSetPlayerSkin'] = { 'int32', 'int32', 153 },
            ['onSetInterior'] = { 'int8', 156 },
            ['onSetCameraPosition'] = { 'vector3d', 157 },
            ['onSetCameraLookAt'] = { 'vector3d', 'int8', 158 },
            ['onSetVehiclePosition'] = { 'int16', 'vector3d', 159 },
            ['onSetVehicleAngle'] = { 'int16', 'float', 160 },
            ['onSetVehicleParams'] = { 'int16', 'int16', 'bool8', 161 },
            --['onSetCameraBehind'] = { 162 },
            ['onChatMessage'] = { 'int16', 'string8', 101 },
            ['onConnectionRejected'] = { 'int8', 130 },
            ['onPlayerStreamOut'] = { 'int16', 163 },
            ['onVehicleStreamIn'] = { 164 },
            ['onVehicleStreamOut'] = { 'int16', 165 },
            ['onPlayerDeath'] = { 'int16', 166 },
            ['onPlayerEnterVehicle'] = { 'int16', 'int16', 'bool8', 26 },
            ['onUpdateScoresAndPings'] = { 'PlayerScorePingMap', 155 },
            ['onSetObjectMaterial'] = { 84 },
            ['onSetObjectMaterialText'] = { 84 },
            ['onSetVehicleParamsEx'] = { 'int16', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 'int8', 24 },
            ['onSetPlayerAttachedObject'] = { 'int16', 'int32', 'bool', 'int32', 'int32', 'vector3d', 'vector3d', 'vector3d', 'int32', 'int32', 113 }
    
        }
        local handler_hook = {
            ['onInitGame'] = true,
            ['onCreateObject'] = true,
            ['onInitMenu'] = true,
            ['onShowTextDraw'] = true,
            ['onVehicleStreamIn'] = true,
            ['onSetObjectMaterial'] = true,
            ['onSetObjectMaterialText'] = true
        }
        local extra = {
            ['PlayerScorePingMap'] = true,
            ['Int32Array3'] = true
        }
        local hook_table = hooks[hook]
        if hook_table then
            local bs = raknetNewBitStream()
            if not handler_hook[hook] then
                local max = #hook_table-1
                if max > 0 then
                    for i = 1, max do
                        local p = hook_table[i]
                        if extra[p] then extra_types[p]['write'](bs, parameters[i])
                        else bs_io[p]['write'](bs, parameters[i]) end
                    end
                end
            else
                if hook == 'onInitGame' then handler.on_init_game_writer(bs, parameters)
                elseif hook == 'onCreateObject' then handler.on_create_object_writer(bs, parameters)
                elseif hook == 'onInitMenu' then handler.on_init_menu_writer(bs, parameters)
                elseif hook == 'onShowTextDraw' then handler.on_show_textdraw_writer(bs, parameters)
                elseif hook == 'onVehicleStreamIn' then handler.on_vehicle_stream_in_writer(bs, parameters)
                elseif hook == 'onSetObjectMaterial' then handler.on_set_object_material_writer(bs, parameters, 1)
                elseif hook == 'onSetObjectMaterialText' then handler.on_set_object_material_writer(bs, parameters, 2) end
            end
            raknetEmulRpcReceiveBitStream(hook_table[#hook_table], bs)
            raknetDeleteBitStream(bs)
        end
    end

    styles = {
        {
            name = u8'Строгий',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                style.WindowRounding = 0
                style.ChildRounding = 0
                style.FrameRounding = 0
                style.ItemSpacing = imgui.ImVec2(3.0, 3.0)
                style.ItemInnerSpacing = imgui.ImVec2(3.0, 3.0)
                style.FramePadding = imgui.ImVec2(4.0, 3.0)
                style.IndentSpacing = 21
                style.ScrollbarSize = 15.0
                style.ScrollbarRounding = 0
                style.GrabMinSize = 17.0
                style.GrabRounding = 0
                style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
                style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
            end
        },
        {
            name = u8'Мягкий',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                style.WindowRounding = 10
                style.ChildRounding = 10
                style.FrameRounding = 6.0
                style.ItemSpacing = imgui.ImVec2(3.0, 3.0)
                style.ItemInnerSpacing = imgui.ImVec2(3.0, 3.0)
                style.FramePadding = imgui.ImVec2(4.0, 3.0)
                style.IndentSpacing = 21
                style.ScrollbarSize = 17.0
                style.ScrollbarRounding = 13
                style.GrabMinSize = 17.0
                style.GrabRounding = 16.0
                style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
                style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
            end
        }
    }
    
    themes = {
        {
            name = u8'Зелёная',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.Text]				   = ImVec4(0.90, 0.90, 0.90, 1.00)
                colors[clr.TextDisabled]		   = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.WindowBg]			   = ImVec4(0.08, 0.08, 0.08, 1.00)
                colors[clr.ChildBg]		  = ImVec4(0.10, 0.10, 0.10, 0.40)
                colors[clr.PopupBg]				= ImVec4(0.08, 0.08, 0.08, 1.00)
                colors[clr.Border]				 = ImVec4(0.70, 0.70, 0.70, 0.40)
                colors[clr.BorderShadow]		   = ImVec4(0.00, 0.00, 0.00, 0.00)
                colors[clr.FrameBg]				= ImVec4(0.15, 0.15, 0.15, 1.00)
                colors[clr.FrameBgHovered]		 = ImVec4(0.19, 0.19, 0.19, 0.71)
                colors[clr.FrameBgActive]		  = ImVec4(0.34, 0.34, 0.34, 0.79)
                colors[clr.TitleBg]				= ImVec4(0.00, 0.69, 0.33, 0.80)
                colors[clr.TitleBgActive]		  = ImVec4(0.00, 0.74, 0.36, 1.00)
                colors[clr.TitleBgCollapsed]	   = ImVec4(0.00, 0.69, 0.33, 0.50)
                colors[clr.MenuBarBg]			  = ImVec4(0.00, 0.80, 0.38, 1.00)
                colors[clr.ScrollbarBg]			= ImVec4(0.16, 0.16, 0.16, 1.00)
                colors[clr.ScrollbarGrab]		  = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
                colors[clr.ScrollbarGrabActive]	= ImVec4(0.00, 1.00, 0.48, 1.00)
                colors[clr.CheckMark]			  = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.SliderGrab]			 = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.SliderGrabActive]	   = ImVec4(0.00, 0.77, 0.37, 1.00)
                colors[clr.Button]				 = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.ButtonHovered]		  = ImVec4(0.00, 0.82, 0.39, 1.00)
                colors[clr.ButtonActive]		   = ImVec4(0.00, 0.87, 0.42, 1.00)
                colors[clr.Header]				 = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.HeaderHovered]		  = ImVec4(0.00, 0.76, 0.37, 0.57)
                colors[clr.HeaderActive]		   = ImVec4(0.00, 0.88, 0.42, 0.89)
                colors[clr.Separator]			  = ImVec4(1.00, 1.00, 1.00, 0.40)
                colors[clr.SeparatorHovered]	   = ImVec4(1.00, 1.00, 1.00, 0.60)
                colors[clr.SeparatorActive]		= ImVec4(1.00, 1.00, 1.00, 0.80)
                colors[clr.ResizeGrip]			 = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.ResizeGripHovered]	  = ImVec4(0.00, 0.76, 0.37, 1.00)
                colors[clr.ResizeGripActive]	   = ImVec4(0.00, 0.86, 0.41, 1.00)
                colors[clr.PlotLines]			  = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.PlotLinesHovered]	   = ImVec4(0.00, 0.74, 0.36, 1.00)
                colors[clr.PlotHistogram]		  = ImVec4(0.00, 0.69, 0.33, 1.00)
                colors[clr.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
                colors[clr.TextSelectedBg]		 = ImVec4(0.00, 0.69, 0.33, 0.72)
                colors[clr.ModalWindowDimBg]   = ImVec4(0.17, 0.17, 0.17, 0.48)
            end
        },
        {
            name = u8'Красная',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.Text]				   = ImVec4(0.95, 0.96, 0.98, 1.00)
                colors[clr.TextDisabled]		   = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.WindowBg]			   = ImVec4(0.14, 0.14, 0.14, 1.00)
                colors[clr.ChildBg]		  = ImVec4(0.12, 0.12, 0.12, 0.40)
                colors[clr.PopupBg]				= ImVec4(0.08, 0.08, 0.08, 0.94)
                colors[clr.Border]				 = ImVec4(0.14, 0.14, 0.14, 1.00)
                colors[clr.BorderShadow]		   = ImVec4(1.00, 1.00, 1.00, 0.00)
                colors[clr.FrameBg]				= ImVec4(0.22, 0.22, 0.22, 1.00)
                colors[clr.FrameBgHovered]		 = ImVec4(0.18, 0.18, 0.18, 1.00)
                colors[clr.FrameBgActive]		  = ImVec4(0.09, 0.12, 0.14, 1.00)
                colors[clr.TitleBg]				= ImVec4(0.14, 0.14, 0.14, 0.81)
                colors[clr.TitleBgActive]		  = ImVec4(0.14, 0.14, 0.14, 1.00)
                colors[clr.TitleBgCollapsed]	   = ImVec4(0.00, 0.00, 0.00, 0.51)
                colors[clr.MenuBarBg]			  = ImVec4(0.20, 0.20, 0.20, 1.00)
                colors[clr.ScrollbarBg]			= ImVec4(0.02, 0.02, 0.02, 0.39)
                colors[clr.ScrollbarGrab]		  = ImVec4(0.36, 0.36, 0.36, 1.00)
                colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00)
                colors[clr.ScrollbarGrabActive]	= ImVec4(0.24, 0.24, 0.24, 1.00)
                colors[clr.CheckMark]			  = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.SliderGrab]			 = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.SliderGrabActive]	   = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.Button]				 = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.ButtonHovered]		  = ImVec4(1.00, 0.39, 0.39, 1.00)
                colors[clr.ButtonActive]		   = ImVec4(1.00, 0.21, 0.21, 1.00)
                colors[clr.Header]				 = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.HeaderHovered]		  = ImVec4(1.00, 0.39, 0.39, 1.00)
                colors[clr.HeaderActive]		   = ImVec4(1.00, 0.21, 0.21, 1.00)
                colors[clr.ResizeGrip]			 = ImVec4(1.00, 0.28, 0.28, 1.00)
                colors[clr.ResizeGripHovered]	  = ImVec4(1.00, 0.39, 0.39, 1.00)
                colors[clr.PlotLines]			  = ImVec4(0.61, 0.61, 0.61, 1.00)
                colors[clr.PlotLinesHovered]	   = ImVec4(1.00, 0.43, 0.35, 1.00)
                colors[clr.PlotHistogram]		  = ImVec4(1.00, 0.21, 0.21, 1.00)
                colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.18, 0.18, 1.00)
                colors[clr.TextSelectedBg]		 = ImVec4(1.00, 0.32, 0.32, 1.00)
                colors[clr.ModalWindowDimBg]   = ImVec4(0.26, 0.26, 0.26, 0.60)
            end
        },
        {
            name = u8'Пурпурная',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.FrameBg]				= ImVec4(0.46, 0.11, 0.29, 1.00)
                colors[clr.FrameBgHovered]		 = ImVec4(0.69, 0.16, 0.43, 1.00)
                colors[clr.FrameBgActive]		  = ImVec4(0.58, 0.10, 0.35, 1.00)
                colors[clr.TitleBg]				= ImVec4(0.00, 0.00, 0.00, 1.00)
                colors[clr.TitleBgActive]		  = ImVec4(0.61, 0.16, 0.39, 1.00)
                colors[clr.TitleBgCollapsed]	   = ImVec4(0.00, 0.00, 0.00, 0.51)
                colors[clr.CheckMark]			  = ImVec4(0.94, 0.30, 0.63, 1.00)
                colors[clr.SliderGrab]			 = ImVec4(0.85, 0.11, 0.49, 1.00)
                colors[clr.SliderGrabActive]	   = ImVec4(0.89, 0.24, 0.58, 1.00)
                colors[clr.Button]				 = ImVec4(0.46, 0.11, 0.29, 1.00)
                colors[clr.ButtonHovered]		  = ImVec4(0.69, 0.17, 0.43, 1.00)
                colors[clr.ButtonActive]		   = ImVec4(0.59, 0.10, 0.35, 1.00)
                colors[clr.Header]				 = ImVec4(0.46, 0.11, 0.29, 1.00)
                colors[clr.HeaderHovered]		  = ImVec4(0.69, 0.16, 0.43, 1.00)
                colors[clr.HeaderActive]		   = ImVec4(0.58, 0.10, 0.35, 1.00)
                colors[clr.Separator]			  = ImVec4(0.69, 0.16, 0.43, 1.00)
                colors[clr.SeparatorHovered]	   = ImVec4(0.58, 0.10, 0.35, 1.00)
                colors[clr.SeparatorActive]		= ImVec4(0.58, 0.10, 0.35, 1.00)
                colors[clr.ResizeGrip]			 = ImVec4(0.46, 0.11, 0.29, 0.70)
                colors[clr.ResizeGripHovered]	  = ImVec4(0.69, 0.16, 0.43, 0.67)
                colors[clr.ResizeGripActive]	   = ImVec4(0.70, 0.13, 0.42, 1.00)
                colors[clr.TextSelectedBg]		 = ImVec4(1.00, 0.78, 0.90, 0.35)
                colors[clr.Text]				   = ImVec4(1.00, 1.00, 1.00, 1.00)
                colors[clr.TextDisabled]		   = ImVec4(0.60, 0.19, 0.40, 1.00)
                colors[clr.WindowBg]			   = ImVec4(0.06, 0.06, 0.06, 0.94)
                colors[clr.ChildBg]		  = ImVec4(0.00, 0.00, 0.00, 0.40)
                colors[clr.PopupBg]				= ImVec4(0.08, 0.08, 0.08, 0.94)
                colors[clr.Border]				 = ImVec4(0.49, 0.14, 0.31, 1.00)
                colors[clr.BorderShadow]		   = ImVec4(0.49, 0.14, 0.31, 0.00)
                colors[clr.MenuBarBg]			  = ImVec4(0.15, 0.15, 0.15, 1.00)
                colors[clr.ScrollbarBg]			= ImVec4(0.02, 0.02, 0.02, 0.53)
                colors[clr.ScrollbarGrab]		  = ImVec4(0.31, 0.31, 0.31, 1.00)
                colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
                colors[clr.ScrollbarGrabActive]	= ImVec4(0.51, 0.51, 0.51, 1.00)
                colors[clr.ModalWindowDimBg]   = ImVec4(0.80, 0.80, 0.80, 0.35)
            end
        },
        {
            name = u8'Фиолетовая',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.WindowBg]			  = ImVec4(0.14, 0.12, 0.16, 1.00)
                colors[clr.ChildBg]		 = ImVec4(0.30, 0.20, 0.39, 0.40)
                colors[clr.PopupBg]			   = ImVec4(0.05, 0.05, 0.10, 0.90)
                colors[clr.Border]				= ImVec4(0.89, 0.85, 0.92, 0.30)
                colors[clr.BorderShadow]		  = ImVec4(0.00, 0.00, 0.00, 0.00)
                colors[clr.FrameBg]			   = ImVec4(0.30, 0.20, 0.39, 1.00)
                colors[clr.FrameBgHovered]		= ImVec4(0.41, 0.19, 0.63, 0.68)
                colors[clr.FrameBgActive]		 = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.TitleBg]			   = ImVec4(0.41, 0.19, 0.63, 0.45)
                colors[clr.TitleBgCollapsed]	  = ImVec4(0.41, 0.19, 0.63, 0.35)
                colors[clr.TitleBgActive]		 = ImVec4(0.41, 0.19, 0.63, 0.78)
                colors[clr.MenuBarBg]			 = ImVec4(0.30, 0.20, 0.39, 0.57)
                colors[clr.ScrollbarBg]		   = ImVec4(0.30, 0.20, 0.39, 1.00)
                colors[clr.ScrollbarGrab]		 = ImVec4(0.41, 0.19, 0.63, 0.31)
                colors[clr.ScrollbarGrabHovered]  = ImVec4(0.41, 0.19, 0.63, 0.78)
                colors[clr.ScrollbarGrabActive]   = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.CheckMark]			 = ImVec4(0.56, 0.61, 1.00, 1.00)
                colors[clr.SliderGrab]			= ImVec4(0.41, 0.19, 0.63, 0.24)
                colors[clr.SliderGrabActive]	  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.Button]				= ImVec4(0.41, 0.19, 0.63, 0.44)
                colors[clr.ButtonHovered]		 = ImVec4(0.41, 0.19, 0.63, 0.86)
                colors[clr.ButtonActive]		  = ImVec4(0.64, 0.33, 0.94, 1.00)
                colors[clr.Header]				= ImVec4(0.41, 0.19, 0.63, 0.76)
                colors[clr.HeaderHovered]		 = ImVec4(0.41, 0.19, 0.63, 0.86)
                colors[clr.HeaderActive]		  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.ResizeGrip]			= ImVec4(0.41, 0.19, 0.63, 0.20)
                colors[clr.ResizeGripHovered]	 = ImVec4(0.41, 0.19, 0.63, 0.78)
                colors[clr.ResizeGripActive]	  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.PlotLines]			 = ImVec4(0.89, 0.85, 0.92, 0.63)
                colors[clr.PlotLinesHovered]	  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.PlotHistogram]		 = ImVec4(0.89, 0.85, 0.92, 0.63)
                colors[clr.PlotHistogramHovered]  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.TextSelectedBg]		= ImVec4(0.41, 0.19, 0.63, 0.43)
                colors[clr.TextDisabled]		  = ImVec4(0.41, 0.19, 0.63, 1.00)
                colors[clr.ModalWindowDimBg]  = ImVec4(0.20, 0.20, 0.20, 0.35)
            end
        },
        {
            name = u8'Вишнёвая',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.Text]				  = ImVec4(0.86, 0.93, 0.89, 0.78)
                colors[clr.TextDisabled]		  = ImVec4(0.71, 0.22, 0.27, 1.00)
                colors[clr.WindowBg]			  = ImVec4(0.13, 0.14, 0.17, 1.00)
                colors[clr.ChildBg]		 = ImVec4(0.20, 0.22, 0.27, 0.58)
                colors[clr.PopupBg]			   = ImVec4(0.20, 0.22, 0.27, 0.90)
                colors[clr.Border]				= ImVec4(0.31, 0.31, 1.00, 0.00)
                colors[clr.BorderShadow]		  = ImVec4(0.00, 0.00, 0.00, 0.00)
                colors[clr.FrameBg]			   = ImVec4(0.20, 0.22, 0.27, 1.00)
                colors[clr.FrameBgHovered]		= ImVec4(0.46, 0.20, 0.30, 0.78)
                colors[clr.FrameBgActive]		 = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.TitleBg]			   = ImVec4(0.23, 0.20, 0.27, 1.00)
                colors[clr.TitleBgActive]		 = ImVec4(0.50, 0.08, 0.26, 1.00)
                colors[clr.TitleBgCollapsed]	  = ImVec4(0.20, 0.20, 0.27, 0.75)
                colors[clr.MenuBarBg]			 = ImVec4(0.20, 0.22, 0.27, 0.47)
                colors[clr.ScrollbarBg]		   = ImVec4(0.20, 0.22, 0.27, 1.00)
                colors[clr.ScrollbarGrab]		 = ImVec4(0.09, 0.15, 0.10, 1.00)
                colors[clr.ScrollbarGrabHovered]  = ImVec4(0.46, 0.20, 0.30, 0.78)
                colors[clr.ScrollbarGrabActive]   = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.CheckMark]			 = ImVec4(0.71, 0.22, 0.27, 1.00)
                colors[clr.SliderGrab]			= ImVec4(0.47, 0.77, 0.83, 0.14)
                colors[clr.SliderGrabActive]	  = ImVec4(0.71, 0.22, 0.27, 1.00)
                colors[clr.Button]				= ImVec4(0.47, 0.77, 0.83, 0.14)
                colors[clr.ButtonHovered]		 = ImVec4(0.46, 0.20, 0.30, 0.86)
                colors[clr.ButtonActive]		  = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.Header]				= ImVec4(0.46, 0.20, 0.30, 0.76)
                colors[clr.HeaderHovered]		 = ImVec4(0.46, 0.20, 0.30, 0.86)
                colors[clr.HeaderActive]		  = ImVec4(0.50, 0.08, 0.26, 1.00)
                colors[clr.ResizeGrip]			= ImVec4(0.47, 0.77, 0.83, 0.04)
                colors[clr.ResizeGripHovered]	 = ImVec4(0.46, 0.20, 0.30, 0.78)
                colors[clr.ResizeGripActive]	  = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.PlotLines]			 = ImVec4(0.86, 0.93, 0.89, 0.63)
                colors[clr.PlotLinesHovered]	  = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.PlotHistogram]		 = ImVec4(0.86, 0.93, 0.89, 0.63)
                colors[clr.PlotHistogramHovered]  = ImVec4(0.46, 0.20, 0.30, 1.00)
                colors[clr.TextSelectedBg]		= ImVec4(0.46, 0.20, 0.30, 0.43)
                colors[clr.ModalWindowDimBg]  = ImVec4(0.20, 0.22, 0.27, 0.73)
            end
        },
        {
            name = u8'Жёлтая',
            func = function()
                imgui.SwitchContext()
                local style = imgui.GetStyle()
                local colors = style.Colors
                local clr = imgui.Col
                local ImVec4 = imgui.ImVec4
                colors[clr.Text]				 = ImVec4(0.92, 0.92, 0.92, 1.00)
                colors[clr.TextDisabled]		 = ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.WindowBg]			 = ImVec4(0.06, 0.06, 0.06, 1.00)
                colors[clr.ChildBg]		= ImVec4(0.00, 0.00, 0.00, 0.40)
                colors[clr.PopupBg]			  = ImVec4(0.08, 0.08, 0.08, 0.94)
                colors[clr.Border]			   = ImVec4(0.51, 0.36, 0.15, 1.00)
                colors[clr.BorderShadow]		 = ImVec4(0.00, 0.00, 0.00, 0.00)
                colors[clr.FrameBg]			  = ImVec4(0.11, 0.11, 0.11, 1.00)
                colors[clr.FrameBgHovered]	   = ImVec4(0.51, 0.36, 0.15, 1.00)
                colors[clr.FrameBgActive]		= ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.TitleBg]			  = ImVec4(0.51, 0.36, 0.15, 1.00)
                colors[clr.TitleBgActive]		= ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.TitleBgCollapsed]	 = ImVec4(0.00, 0.00, 0.00, 0.51)
                colors[clr.MenuBarBg]			= ImVec4(0.11, 0.11, 0.11, 1.00)
                colors[clr.ScrollbarBg]		  = ImVec4(0.06, 0.06, 0.06, 0.53)
                colors[clr.ScrollbarGrab]		= ImVec4(0.21, 0.21, 0.21, 1.00)
                colors[clr.ScrollbarGrabHovered] = ImVec4(0.47, 0.47, 0.47, 1.00)
                colors[clr.ScrollbarGrabActive]  = ImVec4(0.81, 0.83, 0.81, 1.00)
                colors[clr.CheckMark]			= ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.SliderGrab]		   = ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.SliderGrabActive]	 = ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.Button]			   = ImVec4(0.51, 0.36, 0.15, 1.00)
                colors[clr.ButtonHovered]		= ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.ButtonActive]		 = ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.Header]			   = ImVec4(0.51, 0.36, 0.15, 1.00)
                colors[clr.HeaderHovered]		= ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.HeaderActive]		 = ImVec4(0.93, 0.65, 0.14, 1.00)
                colors[clr.Separator]			= ImVec4(0.21, 0.21, 0.21, 1.00)
                colors[clr.SeparatorHovered]	 = ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.SeparatorActive]	  = ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.ResizeGrip]		   = ImVec4(0.21, 0.21, 0.21, 1.00)
                colors[clr.ResizeGripHovered]	= ImVec4(0.91, 0.64, 0.13, 1.00)
                colors[clr.ResizeGripActive]	 = ImVec4(0.78, 0.55, 0.21, 1.00)
                colors[clr.PlotLines]			= ImVec4(0.61, 0.61, 0.61, 1.00)
                colors[clr.PlotLinesHovered]	 = ImVec4(1.00, 0.43, 0.35, 1.00)
                colors[clr.PlotHistogram]		= ImVec4(0.90, 0.70, 0.00, 1.00)
                colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
                colors[clr.TextSelectedBg]	   = ImVec4(0.26, 0.59, 0.98, 0.35)
                colors[clr.ModalWindowDimBg] = ImVec4(0.80, 0.80, 0.80, 0.35)
            end
        },
        {
            name = u8'Кровавая',
            func = function()
        imgui.SwitchContext()
        local ImVec4 = imgui.ImVec4
        imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
        imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
        imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
        imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
        imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
        imgui.GetStyle().IndentSpacing = 0
        imgui.GetStyle().ScrollbarSize = 10
        imgui.GetStyle().GrabMinSize = 10
        imgui.GetStyle().WindowBorderSize = 1
        imgui.GetStyle().ChildBorderSize = 1
    
        imgui.GetStyle().PopupBorderSize = 1
        imgui.GetStyle().FrameBorderSize = 1
        imgui.GetStyle().TabBorderSize = 1
        imgui.GetStyle().WindowRounding = 8
        imgui.GetStyle().ChildRounding = 8
        imgui.GetStyle().FrameRounding = 8
        imgui.GetStyle().PopupRounding = 8
        imgui.GetStyle().ScrollbarRounding = 8
        imgui.GetStyle().GrabRounding = 8
        imgui.GetStyle().TabRounding = 8
    
        imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 0.43);
        imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 0.90);
        imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(1.00, 1.00, 1.00, 0.07);
        imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 0.94);
        imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(1.00, 1.00, 1.00, 0.00);
        imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(1.00, 0.00, 0.00, 0.32);
        imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.09);
        imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(1.00, 1.00, 1.00, 0.17);
        imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(1.00, 1.00, 1.00, 0.26);
        imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.19, 0.00, 0.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.46, 0.00, 0.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.20, 0.00, 0.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.14, 0.03, 0.03, 1.00);
        imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.19, 0.00, 0.00, 0.53);
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.11);
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.24);
        imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(1.00, 1.00, 1.00, 0.35);
        imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(1.00, 0.00, 0.00, 0.34);
        imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(1.00, 0.00, 0.00, 0.51);
        imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(1.00, 0.00, 0.00, 0.19);
        imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(1.00, 0.00, 0.00, 0.31);
        imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(1.00, 0.00, 0.00, 0.46);
        imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(1.00, 0.00, 0.00, 0.19);
        imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(1.00, 0.00, 0.00, 0.30);
        imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(1.00, 0.00, 0.00, 0.50);
        imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(1.00, 0.00, 0.00, 0.41);
        imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.78);
        imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.19, 0.00, 0.00, 0.53);
        imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.43, 0.00, 0.00, 0.75);
        imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.53, 0.00, 0.00, 0.95);
        imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(1.00, 0.00, 0.00, 0.27);
        imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(1.00, 0.00, 0.00, 0.48);
        imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(1.00, 0.00, 0.00, 0.60);
        imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(1.00, 0.00, 0.00, 0.27);
        imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(1.00, 0.00, 0.00, 0.54);
        imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
        imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00);
        imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00);
        imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35);
        imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = ImVec4(1.00, 1.00, 0.00, 0.90);
        imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = ImVec4(0.26, 0.59, 0.98, 1.00);
        imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = ImVec4(1.00, 1.00, 1.00, 0.70);
        imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = ImVec4(0.80, 0.80, 0.80, 0.20);
        imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = ImVec4(0.80, 0.80, 0.80, 0.35);
    end
        },
        {
            name = u8'Синяя',
            func = function()
                local ImVec4 = imgui.ImVec4
                imgui.SwitchContext()
                imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
                imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
                imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
                imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
                imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
                imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
                imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
                imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
                imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
                imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
                imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
                imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
                imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
                imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
                imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
                imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
                imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.06, 0.53, 0.98, 0.70)
                imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.10, 0.10, 0.10, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.06, 0.53, 0.98, 0.70)
                imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
                imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
                imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
            end
        },
        {
            name = u8'Красная',
            func = function()
                local ImVec4 = imgui.ImVec4
                imgui.SwitchContext()
                imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
                imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
                imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(1.00, 1.00, 1.00, 0.00)
                imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
                imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
                imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
                imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
                imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
                imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
                imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
                imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
                imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
                imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
                imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
                imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
                imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
                imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
                imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
                imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
                imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
                imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
                imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.98, 0.26, 0.26, 0.40)
                imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.98, 0.06, 0.06, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(0.98, 0.26, 0.26, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
                imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
                imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
            end
        },
    }