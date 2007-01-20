pump_on = 0;


  setlistener("/sim/signals/fdm-initialized", func {
     setprop("/controls/fuel/switch-position",-1);
     setprop("/consumables/fuel/tank[0]/selected",0);
     setprop("/consumables/fuel/tank[1]/selected",0);
     setprop("/consumables/fuel/tank[2]/selected",0);
     }, 1);
 
setlistener("/controls/fuel/switch-position", func {
    position=cmdarg().getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
    setprop("/consumables/fuel/tank[2]/selected",0);
    if(position >= 0.0){
    setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
        };    
    }, 1);

setlistener("/sim/crashed", func {
    crash=cmdarg().getValue();
    if(crash != 0){
    props.globals.getNode("/engines/engine/running").setBoolValue(0);
    props.globals.getNode("/engines/engine/rpm").setValue(0);
        };    
    }, 1);


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



pump_on = getprop("/controls/engines/engine[0]/fuel-pump");
testfuel = getprop("/controls/fuel/switch-position");
if(pump_on == 0){setprop("/engines/engine/out-of-fuel",1)}else{
if(testfuel > -1){
if(getprop("/consumables/fuel/tank[" ~ testfuel ~ "]/level-gal_us") > 0.01){
setprop("/engines/engine/out-of-fuel",0);} 
}}

oil_psi = getprop("/engines/engine/rpm") * 0.001;
if(oil_psi > 1.0){oil_psi = 1.0};
setprop("/engines/engine/oil-pressure-psi",oil_psi);



settimer(gforce, 0);
}
settimer(gforce, 0);
