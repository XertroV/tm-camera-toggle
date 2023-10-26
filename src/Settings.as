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

enum ToggleMode {
    Toggle2 = 2, Toggle3 = 3
}

[Setting category="General" name="Camera A"]
CamChoice S_CameraA = CamChoice::Cam1;

[Setting category="General" name="Camera B"]
CamChoice S_CameraB = CamChoice::Cam2;

[Setting category="General" name="Camera C" description="This is only used when the 'Toggle 3' mode is set."]
CamChoice S_CameraC = CamChoice::Cam3;

[Setting category="General" name="Toggle Mode" description="Whether to toggle between just Cameras A and B, or between all 3."]
ToggleMode S_ToggleMode = ToggleMode::Toggle2;



[Setting category="2nd Button" name="Enable 2nd Button?"]
bool S_SecondButtonEnabled = false;

[Setting category="2nd Button" name="2nd Toggle Button"]
Button S_SecondButton = Button::L2;

[Setting category="2nd Button" name="Camera A"]
CamChoice S_SecondCameraA = CamChoice::Cam1;

[Setting category="2nd Button" name="Camera B"]
CamChoice S_SecondCameraB = CamChoice::Cam2;


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
