class CameraStatus {
    bool isAlt;
    bool canDrive;
    uint currCam;
    CameraStatus(bool isAlt, bool canDrive, uint currCam) {
        this.isAlt = isAlt;
        this.canDrive = canDrive;
        this.currCam = currCam;
    }
    CameraStatus() {}

    string ToString() const {
        if (currCam == 0) return "None";
        return tostring(CameraType(currCam)) + " [" + tostring(CGameItemModel::EnumDefaultCam(currCam)) + "]" + (isAlt ? " (alt)" : "") + (canDrive ? " (drivable)" : "");
    }
}

CameraStatus@ GetCameraStatus() {
    auto gt = GetGameTerminal(GetApp());
    if (gt is null) return CameraStatus();
	bool alt = Dev::GetOffsetUint16(gt, 0x30) == 0x0;
	auto canDrive = Dev::GetOffsetUint32(gt, 0x60) == 0x0;
	auto currCam = Dev::GetOffsetUint32(gt, 0x34);
    return CameraStatus(alt, canDrive, currCam);
}

CGameTerminal@ GetGameTerminal(CGameCtnApp@ app) {
	if (app.CurrentPlayground is null) return null;
	if (app.CurrentPlayground.GameTerminals.Length == 0) return null;
	auto gt = app.CurrentPlayground.GameTerminals[0];
    return gt;
}

void SetAltCamFlag(CGameCtnApp@ app, bool isAlt) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
    Dev::SetOffset(gt, 0x30, isAlt ? 0x0 : 0x1);
}

void SetDrivableCamFlag(CGameCtnApp@ app, bool canDrive) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
    Dev::SetOffset(gt, 0x60, canDrive ? 0x0 : 0x1);
}

// crashes on 0x8, 0x9, and 0x1e or greater
// 3,4,5,6 are some kind of default cams where you need to toggle free cam drivable to drive
enum CameraType {
    FreeCam = 0x2,
    WeirdDefault = 0x5,
    Intro7Mb = 0x7,
    Intro10Mb = 0x10,
    FreeCam2 = 0x11,
    Cam1 = 0x12,
    Cam2 = 0x13,
    Cam3 = 0x14,
    Backwards = 0x15,
    Intro16Mb = 0x16,
    // same repeated up to 0x1d
    // Intro1dMb = 0x1d,
}

// enum CGameItemModel::EnumDefaultCam {
//     None = 0,
//     Default = 1,
//     Free = 2,
//     Spectator = 3,
//     Behind = 4,
//     Close = 5,
//     Internal = 6,
//     Helico = 7,
//     FirstPerson = 8,
//     ThirdPerson = 9,
//     ThirdPersonTop = 10,
//     Iso = 11,
//     IsoFocus = 12,
//     Dia3 = 13,
//     Board = 14,
//     MonoScreen = 15,
//     Rear = 16,
//     Debug = 17,
//     _1 = 18, // 1
//     _2 = 19, // 2
//     _3 = 20, // 3
//     Alt1 = 21,
//     Orbital = 22,
//     Decals = 23,
//     Snap = 24,
//     NearOpponents = 25,
//     MapThumbnail = 26,
// }

void SetCamType(CGameCtnApp@ app, CameraType cam) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
	auto setCamNod = Dev::GetOffsetNod(gt, 0x50);
    Dev::SetOffset(setCamNod, 0x4, uint(cam));
    if (S_PersistCameraBetweenMaps)
        SetCamNextMap(app, cam);
}


// This governs which camera persists between maps, but does not change the active cam
void SetCamNextMap(CGameCtnApp@ app, CameraType cam) {
    auto profile = GetSpecialUserProfile(app);
    if (profile is null) return;
    auto bufLen = Dev::GetOffsetUint32(profile, O_UserProfile_CameraLastNodBuf + 0x8);
    if (bufLen == 0 || bufLen > 20) return;
    auto cameraSettingPtr = Dev::GetOffsetUint64(profile, O_UserProfile_CameraLastNodBuf) + 0x4;
    Dev::Write(cameraSettingPtr, uint(cam));
}


// ! -- The below is from Autohide Opponents


// user profile
uint O_UserProfile_CameraLastNodBuf = 0x98;

// updated 2024-04-28: +0x8 to both.
uint SpecialUserProfileOffset = 0x28;


CGameUserProfile@ GetSpecialUserProfile(CGameCtnApp@ app) {
    if (!GameVersionSafe) {
        // warn("Call to unsafe dev method");
        return null;
    }
    auto appTy = Reflection::GetType("CTrackMania");
    auto rootMapM = appTy.GetMember("RootMap");
    // orig 0x3a0 = 0x358 + 0x48
    auto off1 = rootMapM.Offset + 0x48;
    int[] offsets = {off1, 0, SpecialUserProfileOffset};
    auto fakeNod1 = Dev::GetOffsetNod(app, offsets[0]);
    auto fakeNod2 = Dev::GetOffsetNod(fakeNod1, offsets[1]);
    auto nod3 = Dev::GetOffsetNod(fakeNod2, offsets[2]);
    return cast<CGameUserProfile>(nod3);
}
