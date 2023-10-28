void Main() {
    startnew(CheckAndSetGameVersionSafe);
}
void OnDestroyed() { }
void OnDisabled() { OnDestroyed(); }

const string PluginIcon = Icons::VideoCamera + Icons::Refresh;
const string MenuName = PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    if (UI::BeginMenu(MenuName)) {
        auto cur = UI::GetCursorPos();
        UI::Dummy(vec2(150, 0));
        UI::SetCursorPos(cur);
        if (UI::MenuItem("Enabled", "", S_Enabled)) {
            S_Enabled = !S_Enabled;
        }
        UI::Separator();
        if (UI::MenuItem("Mode: Toggle 2 cams", "", S_ToggleMode == ToggleMode::Toggle2)) {
            S_ToggleMode = ToggleMode::Toggle2;
        }
        UI::TextWrapped("\\$888Toggle 2 cams will toggle between your chosen cameras: "+tostring(S_CameraA)+" and "+tostring(S_CameraB)+".");
        UI::Separator();
        if (UI::MenuItem("Mode: Toggle 3 cams", "", S_ToggleMode == ToggleMode::Toggle3)) {
            S_ToggleMode = ToggleMode::Toggle3;
        }
        UI::TextWrapped("\\$888Toggle 3 cams toggles between all 3 -- use it to avoid going into settings to rebind.");
        UI::EndMenu();
    }
}

CameraType GetCameraType(CamChoice cam) {
    if (cam == CamChoice::Cam1 || cam == CamChoice::Cam1Alt) return CameraType::Cam1;
    if (cam == CamChoice::Cam2 || cam == CamChoice::Cam2Alt) return CameraType::Cam2;
    if (cam == CamChoice::Cam3 || cam == CamChoice::Cam3Alt) return CameraType::Cam3;
    if (cam == CamChoice::Cam7 || cam == CamChoice::Cam7Drivable) return CameraType::FreeCam;
    if (cam == CamChoice::CamBackwards) return CameraType::Backwards;
    return CameraType::Cam1;
}
bool IsAltCam(CamChoice cam) {
    return cam == CamChoice::Cam1Alt || cam == CamChoice::Cam2Alt || cam == CamChoice::Cam3Alt;
}
bool IsDrivableCam(CamChoice cam) {
    return cam == CamChoice::Cam7Drivable;
}

void SetCamChoice(CamChoice cam) {
    lastSetCamChoice = cam;
    auto setTo = GetCameraType(cam);
    auto alt = IsAltCam(cam);
    auto drivable = IsDrivableCam(cam);
    auto app = GetApp();
    SetAltCamFlag(app, alt);
    SetDrivableCamFlag(app, drivable);
    SetCamType(app, setTo);
}

bool[] newButtonsPressed = array<bool>(16);
bool[] lastButtonsPressed = array<bool>(16);
bool[] nextButtonsPressed = array<bool>(16);

enum Button {
    Left = 0, Right, Up, Down,
    A, B, X, Y, L1, L2, L3, R1, R2, R3,
    Menu, View,
}

/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    if (!S_Enabled) return;

    auto app = GetApp();

    auto input = app.InputPort;

    for (uint i = 0; i < nextButtonsPressed.Length; i++) {
        nextButtonsPressed[i] = false;
    }

    for (uint i = 0; i < input.Script_Pads.Length; i++) {
        auto pad = input.Script_Pads[i];
        if (pad.Type >= 2) {
            UpdateButtonPressed(pad.Left, Button::Left);
            UpdateButtonPressed(pad.Right, Button::Right);
            UpdateButtonPressed(pad.Up, Button::Up);
            UpdateButtonPressed(pad.Down, Button::Down);
            UpdateButtonPressed(pad.A, Button::A);
            UpdateButtonPressed(pad.B, Button::B);
            UpdateButtonPressed(pad.X, Button::X);
            UpdateButtonPressed(pad.Y, Button::Y);
            UpdateButtonPressed(pad.L1, Button::L1);
            UpdateButtonPressed(pad.L2 > 0 ? 1 : 0, Button::L2);
            UpdateButtonPressed(pad.LeftStickBut, Button::L3);
            UpdateButtonPressed(pad.R1, Button::R1);
            UpdateButtonPressed(pad.R2 > 0 ? 1 : 0, Button::R2);
            UpdateButtonPressed(pad.RightStickBut, Button::R3);
            UpdateButtonPressed(pad.Menu, Button::Menu);
            UpdateButtonPressed(pad.View, Button::View);
        }
    }

    for (uint i = 0; i < newButtonsPressed.Length; i++) {
        newButtonsPressed[i] = !lastButtonsPressed[i] && nextButtonsPressed[i];
        lastButtonsPressed[i] = nextButtonsPressed[i];
    }

    // update in the menu so settings preview of button presses works. but we don't want to try and toggle the camera in the menu
    if (app.CurrentPlayground is null) return;

    CheckForTogglePress();
}

void UpdateButtonPressed(uint value, Button button) {
    nextButtonsPressed[button] = nextButtonsPressed[button] || value > 0;
}

uint toggleState = 0;
uint toggleState2 = 0;
CamChoice lastSetCamChoice = CamChoice::CamBackwards;

void CheckForTogglePress() {
    auto btn1Pressed = newButtonsPressed[S_Button];
    auto btn2Pressed = S_SecondButtonEnabled && newButtonsPressed[S_SecondButton];
    CamChoice choice = lastSetCamChoice;
    if (btn1Pressed) {
        // trace('toggling camera');
        toggleState = (toggleState + 1) % uint(S_ToggleMode);
        choice = toggleState == 0 ? S_CameraA : toggleState == 1 ? S_CameraB : S_CameraC;
        toggleState2 = uint(-1);
    } else if (btn2Pressed) {
        toggleState2 = (toggleState2 + 1) % 2;
        choice = toggleState2 == 0 ? S_SecondCameraA : S_SecondCameraB;
        toggleState = uint(-1);
    } else {
        return;
    }

    if (choice == lastSetCamChoice) {
        // don't change to the last camera we changed to, just recall this function to increment and return;
        CheckForTogglePress();
        return;
    }
    SetCamChoice(choice);
}


void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}
