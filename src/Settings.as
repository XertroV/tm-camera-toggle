[Setting category="General" name="Enabled"]
bool S_Enabled = true;

[Setting category="General" name="Toggle Button"]
Button S_Button = Button::L1;

enum CamChoice {
    Cam1, Cam1Alt,
    Cam2, Cam2Alt,
    Cam3, Cam3Alt,
    Cam7, Cam7Drivable,
    CamBackwards,
}

[Setting category="General" name="Camera A"]
CamChoice S_CameraA = CamChoice::Cam1;

[Setting category="General" name="Camera B"]
CamChoice S_CameraB = CamChoice::Cam2;

[SettingsTab name="Debug"]
void S_DebugTab() {
    UI::TextWrapped("Current Camera: " + GetCameraStatus().ToString());

    UI::Separator();

    if (!S_Enabled) {
        UI::Text("\\$f80Warning: button presses are not updated when the plugin is disabled");
    }

    UI::Text("Buttons Pressed:");
    UI::Indent();
    for (uint i = 0; i <= Button::View; i++) {
        UI::Text(tostring(Button(i)) + ": " + lastButtonsPressed[i]);
    }
    UI::Unindent();
}
