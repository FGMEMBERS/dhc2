aircraft.livery.init("Aircraft/dhc2/Models/Liveries");
var Radio = gui.Dialog.new("/sim/gui/dialogs/radios/dialog",
        "Aircraft/dhc2/Systems/radios.xml");
var options = gui.Dialog.new("/sim/gui/dialogs/options/dialog",
        "Aircraft/dhc2/Systems/options.xml");
var ap_settings = gui.Dialog.new("/sim/gui/dialogs/autopilot/dialog",
        "Aircraft/dhc2/Systems/autopilot-dlg.xml");
gui.menuBind("radio", "dialogs.Radio.open()");
gui.menuBind("autopilot-settings", "dialogs.ap_settings.open()");
