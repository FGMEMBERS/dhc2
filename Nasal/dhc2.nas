var pump_on = 0;
var rud_swingtime = 2;  # how long complete movement should last
var rud_target = 1;
var rud_prop = props.globals.getNode("/controls/gear/water-rudder-down", 1);
var wake1 = props.globals.getNode("/ai/submodels/wake[0]", 1);
var wake2 = props.globals.getNode("/ai/submodels/wake[1]", 1);
var gear_roll = props.globals.getNode("/gear/gear[0]/rollspeed-ms", 1);

    wake1.setBoolValue(0);
    wake2.setBoolValue(0);

setlistener("/sim/signals/fdm-initialized", func {
     setprop("/controls/fuel/switch-position",-1);
     setprop("/engines/engine/oil-temp-norm",0.0);
     setprop("/controls/gear/water-rudder-down",0);
     setprop("/consumables/fuel/tank[0]/selected",0);
     setprop("/consumables/fuel/tank[1]/selected",0);
     setprop("/consumables/fuel/tank[2]/selected",0);
     setprop("/consumables/fuel/tank[0]/selected",0);
     });
 
setlistener("/controls/fuel/switch-position", func {
    position=cmdarg().getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    if(position >= 0.0){
    setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
        };    
    }, 1);

water_rudder = func{
    var time = abs(rud_prop.getValue() - rud_target) * rud_swingtime;
    interpolate(rud_prop, rud_target, time);
    rud_target = !rud_target;
}

starter = func{
    engage = arg[0];
    if (getprop("/controls/electric/battery-switch")!=0){
    setprop("/controls/engines/engine/starter",engage);
    }
}


gforce = func{
    force = getprop("/accelerations/pilot-g");
    if(force == nil) {force = 1.0;}
    eyepoint = getprop("sim/view/config/y-offset-m") +0.02;
    eyepoint -= (force * 0.02);
if(getprop("/sim/current-view/view-number") < 1){
setprop("/sim/current-view/y-offset-m",eyepoint);
     }
}

steering = func{
if(getprop("/controls/gear/water-rudder-down") >= 0.9){
    setprop("/controls/gear/water-rudder-pos",getprop("/controls/flight/rudder"));
    }else{
    setprop("/controls/gear/water-rudder-pos",0);}
}

oil_temp = func{
if(getprop("/engines/engine/running") != 0){
    interpolate("/engines/engine/oil-temp-norm", 0.7 + (getprop("/controls/engines/engine/throttle")* 0.3), 300);
    }else{
    interpolate("/engines/engine/oil-temp-norm", 0.0, 1000);
    }
}

fluids_update = func{
var pump_on = getprop("/controls/engines/engine[0]/fuel-pump");
var testfuel = getprop("/controls/fuel/switch-position");
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

update_wake = func{
var wk1 = 0;
var wk2 = 0;
var wlspd = gear_roll.getValue();
if(wlspd == nil){wlspd = 0.0;}
if(wlspd > 3.0){
  if(getprop("/gear/gear[0]/wow")){wk1 = 1;}
  if(getprop("/gear/gear[1]/wow")){wk2 = 1;}
  }
wake1.setBoolValue(wk1);
wake2.setBoolValue(wk2);
}

update = func {
    gforce();
    steering();
    oil_temp();
	fluids_update();
   	update_wake();
	settimer(update,0);
}

settimer(update, 0);
