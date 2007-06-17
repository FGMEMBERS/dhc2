var pump_on = 0;
var EyePoint = 0.0;
var ViewNum = 0;
var Cvolume=props.globals.getNode("/sim/sound/DHC2/Cvolume",1);
var Ovolume=props.globals.getNode("/sim/sound/DHC2/Ovolume",1);
var rud_swingtime = 2;  # how long complete movement should last
var rud_target = 1;
var rud_prop = props.globals.getNode("/controls/gear/water-rudder-down", 1);
var wake1 = props.globals.getNode("/gear/gear[2]/wake",1);
var wake2 = props.globals.getNode("/gear/gear[3]/wake",1);
var gear_roll = props.globals.getNode("/gear/gear[0]/rollspeed-ms", 1);
var CRASHED =0;
var F_Switch = props.globals.getNode("/controls/fuel/switch-position",1);
var Oil_Temp = props.globals.getNode("/engines/engine/oil-temp-norm",1);
var E_state = props.globals.getNode("/engines/engine",1);
var E_control = props.globals.getNode("/controls/engines/engine",1);
var FDM=0;
wake1.setBoolValue(0);
wake2.setBoolValue(0);

strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("/controls/lighting/strobe-state", [0.05, 1.30], strobe_switch);

beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("/controls/lighting/beacon-state", [1.0, 1.0], beacon_switch);

setlistener("/sim/signals/fdm-initialized", func {
    EyePoint = props.globals.getNode("sim/view/config/y-offset-m").getValue();
    Cvolume.setValue(0.6);
    Ovolume.setValue(0.2);
    F_Switch.setIntValue(-1);
    Oil_Temp.setDoubleValue(0.0);
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    setprop("/consumables/fuel/tank[0]/selected",0);
    setup_start();
    FDM=1;
    update();
});

setlistener("/sim/signals/reinit", func {
    if(cmdarg().getValue()==0){
    setup_start();
    }
});

setlistener("/sim/current-view/view-number", func {
    ViewNum = cmdarg().getValue();
    if(ViewNum == 0){
        Cvolume.setValue(0.6);
        Ovolume.setValue(0.3);
    }else{
        Cvolume.setValue(0.1);
        Ovolume.setValue(1.0);
    }
},1);

setlistener("/controls/fuel/switch-position", func {
    position=cmdarg().getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    if(position >= 0.0){
        setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
    };
},1);

setlistener("sim/crashed", func {
    if (cmdarg().getBoolValue()) {
    crash(CRASHED = 1);
    }
});

crash = func {
    if (arg[0]) {
        E_state.getChild("running").setValue(0);
        E_state.getChild("rpm").setValue(0);
    }
}

water_rudder = func{
    var time = abs(rud_prop.getValue() - rud_target) * rud_swingtime;
    interpolate(rud_prop, rud_target, time);
    rud_target = !rud_target;
}

starter = func{
    engage = arg[0];
    if (getprop("/controls/electric/battery-switch")!=0){
        E_control.getChild("starter").setValue(engage);
    }
}

steering = func{
    if(getprop("/controls/gear/water-rudder-down") >= 0.9){
        setprop("/controls/gear/water-rudder-pos",getprop("/controls/flight/rudder"));
    }else{
        setprop("/controls/gear/water-rudder-pos",0);
    }
}

oil_temp = func{
    if(getprop("/engines/engine/running") != 0){
        interpolate("/engines/engine/oil-temp-norm", 0.7 + (getprop("/controls/engines/engine/throttle")* 0.3), 300);
    }else{
        interpolate("/engines/engine/oil-temp-norm", 0.0, 1000);
    }
}

fluids_update = func{
    var pump_on = E_control.getChild("fuel-pump").getValue();
    var testfuel = F_Switch.getValue();
    if(pump_on == 0){setprop("/engines/engine/out-of-fuel",1);
    }else{
        if(testfuel > -1){
            if(getprop("/consumables/fuel/tank[" ~ testfuel ~ "]/level-gal_us") > 0.01){
            setprop("/engines/engine/out-of-fuel",0);}
        }
    }
    oil_psi = getprop("/engines/engine/rpm") * 0.002;
    if(oil_psi > 1.0){oil_psi = 1.0};
    setprop("/engines/engine/oil-pressure-psi",oil_psi);
}

setup_start = func{
    if(getprop("/sim/presets/start-in-water")!= 0){
        if(getprop("/sim/presets/airport-id")=="KSFO"){
            setprop("/sim/presets/heading-deg",110);
            setprop("/sim/presets/latitude-deg",37.6158881);
            setprop("/sim/presets/longitude-deg",-122.357962);
            setprop("/position/latitude-deg",37.6158881);
            setprop("/position/longitude-deg",-122.357962);
        }
    }
    if(getprop("/gear/gear/ground-is-solid")){
        setprop("/controls/gear/gear-down",1);
        setprop("/controls/winch/place",0);
        rud_prop.setValue(0);
    }else{
        setprop("/controls/gear/gear-down",0);
        setprop("/controls/winch/place",1);
        rud_prop.setValue(1);
    }
}

update_wake = func{
    var wk1 = 0;
    var wk2 = 0;
    var wlspd = gear_roll.getValue();
    if(wlspd == nil){wlspd = 0.0;}
    if(wlspd > 1.0){
        if(getprop("/gear/gear[2]/wow")){wk1 =1- getprop("gear/gear[2]/ground-is-solid");}
        if(getprop("/gear/gear[3]/wow")){wk2 =1- getprop("gear/gear[3]/ground-is-solid");}
    }
    wake1.setBoolValue(wk1);
    wake2.setBoolValue(wk2);
}

update = func {
    steering();
    oil_temp();
    fluids_update();
   	update_wake();
    settimer(update,0);
}

