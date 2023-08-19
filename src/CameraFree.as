const uint ActiveCamControlOffset = 0x68;

uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}

uint16 GetOffset(CMwNod@ nod, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(nod);
    auto memberTy = ty.GetMember(memberName);
    return memberTy.Offset;
}

CGameControlCameraFree@ GetFreeCamControls(CGameCtnApp@ app) {
    if (app is null) return null;
    if (app.GameScene is null) return null;
    if (app.CurrentPlayground is null) return null;
    // get the game camera struct
    // orig 0x2b8; GameScene at 0x2a8
    auto gameCamCtrl = Dev::GetOffsetNod(app, GetOffset("CGameManiaPlanet", "GameScene") + 0x10);
    if (gameCamCtrl is null) return null;
    if (Dev::GetOffsetUint64(gameCamCtrl, ActiveCamControlOffset) & 0xF != 0) return null;
    return cast<CGameControlCameraFree>(Dev::GetOffsetNod(gameCamCtrl, ActiveCamControlOffset));
}

uint32 FreeCamGetTargetId(CGameControlCameraFree@ cam) {
    // default if nothing is set
    if (cam is null) return 0x0FF00000;
    // Offset at 0x104
    return Dev::GetOffsetUint32(cam, GetOffset(cam, "m_TargetIsEnabled") + 0x4);
}

void FreeCamSetTargetId(CGameControlCameraFree@ cam, uint32 visId, bool setTargetEnabled = true) {
    Dev::SetOffset(cam, GetOffset("CGameControlCameraFree", "m_TargetIsEnabled") + 0x4, visId);
    if (setTargetEnabled) {
        cam.m_TargetIsEnabled = true;
    }
}
