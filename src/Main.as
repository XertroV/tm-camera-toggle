void Main() {}
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

void SetCamChoice(CamChoice cam) {
    bool alt = cam == CamChoice::Cam1Alt || cam == CamChoice::Cam2Alt || cam == CamChoice::Cam3Alt;
    bool drivable = cam == CamChoice::Cam7Drivable;
    CameraType setTo = cam == CamChoice::Cam1 || cam == CamChoice::Cam1Alt
        ? CameraType::Cam1
        : cam == CamChoice::Cam2 || cam == CamChoice::Cam2Alt
            ? CameraType::Cam2
            : cam == CamChoice::Cam3 || cam == CamChoice::Cam3Alt
                ? CameraType::Cam3
                : cam == CamChoice::Cam7 || cam == CamChoice::Cam7Drivable
                    ? CameraType::FreeCam
                    : cam == CamChoice::CamBackwards
                        ? CameraType::Backwards
                        : CameraType::Cam1
        ;
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

void CheckForTogglePress() {
    if (newButtonsPressed[S_Button]) {
        // trace('toggling camera');
        toggleState = (toggleState + 1) % uint(S_ToggleMode);
        if (toggleState == 0) {
            SetCamChoice(S_CameraA);
        } else if (toggleState == 1) {
            SetCamChoice(S_CameraB);
        } else if (toggleState == 2) {
            SetCamChoice(S_CameraC);
        } else {
            SetCamChoice(S_CameraA);
            warn("Got toggle press but found an invalid toggleState: " + toggleState + " (should 0, 1, or 2)");
        }
    }
}
