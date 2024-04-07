bool GameVersionSafe = false;
bool KnownSafe = false;
const string[] KnownSafeVersions = {
    "2024-03-19_14_47",
    "2024-02-26_11_36",
    "2023-09-19_19_09",
    "2023-09-25_23_51"
};

void CheckAndSetGameVersionSafe() {
    EnsureGameVersionCompatibility();
    if (!GameVersionSafe) {
        WarnBadGameVersion();
    }
}

// Call this to block until we know it's safe or it's overridden by the user
void WaitForSafeGameVersion() {
    if (GameVersionSafe) return;
    CheckAndSetGameVersionSafe();
    while (!GameVersionSafe) yield();
}

string TmGameVersion = "";
void EnsureGameVersionCompatibility() {
    if (GameVersionSafe) return;
    TmGameVersion = GetApp().SystemPlatform.ExeVersion;
    GameVersionSafe = KnownSafeVersions.Find(TmGameVersion) > -1;
    KnownSafe = GameVersionSafe;
    if (GameVersionSafe) return;
    bool fromOpenplanet = GetStatusFromOpenplanet();
    trace("Got GameVersionSafe status: " + fromOpenplanet);
    GameVersionSafe = GameVersionSafe || fromOpenplanet;
}

void WarnBadGameVersion() {
    NotifyWarning("Game version ("+TmGameVersion+") not marked as compatible with this version of the plugin -- camera persistence will be innactive.\n(Override in settings)");
}

bool requestStarted = true;
bool requestEnded = true;

bool GetStatusFromOpenplanet() {
    string pluginId = Meta::ExecutingPlugin().ID;
#if DEV
    if (pluginId.EndsWith("-dev"))
        pluginId = pluginId.SubStr(0, pluginId.Length - 4);
#endif
    string configUrl = "https://openplanet.dev/plugin/" + pluginId + "/config/version-compat";
    trace('Version Compat URL: ' + configUrl);
    auto req = Net::HttpGet(configUrl);
    requestStarted = true;
    requestEnded = false;
    while (!req.Finished()) yield();
    if (req.ResponseCode() != 200) {
        warn('getting plugin enabled status: code: ' + req.ResponseCode() + '; error: ' + req.Error() + '; body: ' + req.String());
        return RetryGetStatus(2000);
    }
    requestEnded = true;
    try {
        auto j = Json::Parse(req.String());
        auto myVer = Meta::ExecutingPlugin().Version;
        if (!j.HasKey(myVer) || j[myVer].GetType() != Json::Type::Object) return false;
        // if we have this key, then it's okay
        return j[myVer].HasKey(TmGameVersion);
    } catch {
        warn("exception: " + getExceptionInfo());
        return RetryGetStatus(2000);
    }
}

uint retries = 0;

bool RetryGetStatus(uint delay) {
    trace('retrying GetStatusFromOpenplanet in ' + delay + ' ms');
    sleep(delay);
    retries++;
    if (retries > 5) {
        warn('not retying anymore, too many failures.');
        return false;
    }
    trace('retrying...');
    return GetStatusFromOpenplanet();
}

[SettingsTab name="Game Version Check" icon="ExclamationTriangle" order=20]
void OverrideGameSafetyCheck() {
    UI::Text("Game version safe? " + tostring(GameVersionSafe));
    UI::Text("Check request started: " + tostring(requestStarted));
    UI::Text("Check request ended: " + tostring(requestEnded));
    if (!GameVersionSafe && UI::Button("Disable safety features and run anyway")) {
        GameVersionSafe = true;
    }
}
