var pump_on = 0;
var ViewNum = 0;
var Cvolume=props.globals.getNode("/sim/sound/DHC2/Cvolume",1);
var Ovolume=props.globals.getNode("/sim/sound/DHC2/Ovolume",1);
var rud_swingtime = 2;  # how long complete movement should last
var rud_target = 1;
var rud_prop =props.globals.getNode("/controls/gear/water-rudder-down",0);
var wake1 = props.globals.getNode("/gear/gear[2]/wake",1);
var wake2 = props.globals.getNode("/gear/gear[3]/wake",1);
var CRASHED =0;
var F_Switch = props.globals.getNode("/controls/fuel/switch-position",1);
var Oil_Temp = props.globals.getNode("/engines/engine/oil-temp-norm",1);
var E_state = props.globals.getNode("/engines/engine",1);
var E_control = props.globals.getNode("/controls/engines/engine",1);
var floats = 0;

#Engine sensors class 
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.fdensity = getprop("consumables/fuel/tank/density-ppg");
        if(m.fdensity ==nil)m.fdensity=6.72;
        m.air_temp = props.globals.getNode("environment/temperature-degc",1);
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.condition = props.globals.getNode("controls/engines/engine["~eng_num~"]/condition",1);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.mixture = props.globals.getNode("controls/engines/engine["~eng_num~"]/mixture",1);
        m.rpm = m.eng.getNode("n2",1);
        m.fuel_pph=m.eng.getNode("fuel-flow_pph",1);
        m.oil_temp=m.eng.getNode("oil-temp-c",1);
        m.oil_temp.setDoubleValue(m.air_temp.getValue());
        m.fuel_pph.setDoubleValue(0);
        m.fuel_gph=m.eng.getNode("fuel-flow-gph",1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
    return m;
    },
#### update ####
    update : func{
        me.fuel_pph.setValue(me.fuel_gph.getValue()*me.fdensity);
        var hpsi =me.rpm.getValue();
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
        var OT= me.oil_temp.getValue();
        var rpm = me.rpm.getValue();
        if(OT < rpm)OT+=0.01;
        if(OT > rpm)OT-=0.001;
        me.oil_temp.setValue(OT);
        },
#### check fuel cutoff , copy mixture setting to condition for turboprop ####
    condition_check :  func{
        if(me.cutoff.getBoolValue()){
            me.condition.setValue(0);
            me.running.setBoolValue(0);
        }else{
            me.condition.setValue(me.mixture.getValue());
        }
    }
};

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setValue(0.6);
    Ovolume.setValue(0.2);
    F_Switch.setIntValue(-1);
    Oil_Temp.setDoubleValue(0.0);
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    setprop("/consumables/fuel/tank[0]/selected",0);
    setup_start();
    update();
});

setlistener("/sim/signals/reinit", func(rset) {
    if(rset.getValue()==0){
    setup_start();
    }
},1,0);

setlistener("/sim/current-view/view-number", func(vw){
    ViewNum = vw.getValue();
    if(ViewNum == 0){
        Cvolume.setValue(0.6);
        Ovolume.setValue(0.3);
    }else{
        Cvolume.setValue(0.1);
        Ovolume.setValue(1.0);
    }
},0,0);

setlistener("/controls/fuel/switch-position", func(fl){
    position=fl.getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    if(position >= 0.0){
        setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
    };
},0,0);

setlistener("sim/crashed", func(crsh){
    if (crsh.getBoolValue()) {
    crash(CRASHED = 1);
    }
},0,0);

setlistener("/sim/model/start-idling", func(idle){
    var run= idle.getBoolValue();
    if(run){
    Startup();
    }else{
    Shutdown();
    }
},0,0);

var crash = func {
    if (arg[0]) {
        E_state.getChild("running").setValue(0);
        E_state.getChild("rpm").setValue(0);
    }
}

var secure = func{
    props.globals.getNode("/controls/winch/place").setBoolValue(1);
    settimer(set_winch,1);
}

var set_winch = func{
    props.globals.getNode("/controls/winch/place").setBoolValue(0);
}

var water_rudder = func{
    var time = abs(rud_prop.getValue() - rud_target) * rud_swingtime;
    interpolate(rud_prop, rud_target, time);
    rud_target = !rud_target;
}

var starter = func{
    engage = arg[0];
    if (getprop("/controls/electric/battery-switch")!=0){
        E_control.getChild("starter").setValue(engage);
    }
}

var steering = func{
    if(getprop("/controls/gear/water-rudder-down") >= 0.9){
        setprop("/controls/gear/water-rudder-pos",getprop("/controls/flight/rudder"));
    }else{
        setprop("/controls/gear/water-rudder-pos",0);
    }
}

var oil_temp = func{
    if(getprop("/engines/engine/running") != 0){
        interpolate("/engines/engine/oil-temp-norm", 0.7 + (getprop("/controls/engines/engine/throttle")* 0.3), 300);
    }else{
        interpolate("/engines/engine/oil-temp-norm", 0.0, 1000);
    }
}

var fluids_update = func{
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

var set_gear = func{
    if(getprop("sim/aero")=="dhc2F"){
        if(getprop("gear/gear[0]/ground-is-solid")){
        setprop("controls/gear/gear-down",1);
        setprop("/controls/gear/water-rudder-down",0);
        }else{
            setprop("controls/gear/gear-down",0);
            setprop("/controls/gear/water-rudder-down",1);
            }
    }
}


var setup_start = func{
    if(getprop("sim/aero")=="dhc2F"){
        if(getprop("/sim/presets/start-in-water")){
            if(getprop("/sim/presets/airport-id")=="KSFO"){
                setprop("/sim/presets/heading-deg",110);
                setprop("/sim/presets/latitude-deg",37.6158881);
                setprop("/sim/presets/longitude-deg",-122.357962);
                setprop("/position/latitude-deg",37.6158881);
                setprop("/position/longitude-deg",-122.357962);
                }
            }
        set_gear();
    }
}

var update_wake = func{
    var wk1 = 0;
    var wk2 = 0;
        if(getprop("velocities/groundspeed-kt") > 5.0){
        if(getprop("/gear/gear[2]/wow")){wk1 =1- getprop("gear/gear[2]/ground-is-solid");}
        if(getprop("/gear/gear[3]/wow")){wk2 =1- getprop("gear/gear[3]/ground-is-solid");}
    }
    wake1.setBoolValue(wk1);
    wake2.setBoolValue(wk2);
}

var Startup = func{
setprop("controls/electric/engine[0]/generator",1);
setprop("controls/electric/battery-switch",1);
setprop("controls/lighting/instrument-lights",1);
setprop("controls/lighting/nav-lights",1);
setprop("controls/lighting/beacon",1);
setprop("controls/engines/engine[0]/magnetos",3);
setprop("controls/engines/engine[0]/fuel-pump",1);
setprop("controls/engines/engine[0]/propeller-pitch",1);
setprop("controls/engines/engine[0]/mixture",1);
setprop("controls/fuel/switch-position",0);
setprop("engines/engine[0]/rpm",500);
setprop("engines/engine[0]/running",1);
}

var Shutdown = func{
setprop("controls/electric/engine[0]/generator",0);
setprop("controls/electric/battery-switch",0);
setprop("controls/lighting/instrument-lights",0);
setprop("controls/lighting/nav-lights",0);
setprop("controls/lighting/beacon",0);
setprop("controls/engines/engine[0]/magnetos",0);
setprop("controls/engines/engine[0]/fuel-pump",0);
setprop("controls/engines/engine[0]/propeller-pitch",0);
setprop("controls/engines/engine[0]/mixture",0);
setprop("controls/fuel/switch-position",-1);
setprop("engines/engine[0]/running",0);
}

var update = func {
    
    oil_temp();
    fluids_update();
   	if(floats ==1){
        steering();
        update_wake();
        }
    
    settimer(update,0);
}

