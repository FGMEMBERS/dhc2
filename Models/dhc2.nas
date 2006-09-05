fswitch = nil;
pump_on = 0;
INIT = func {
    fswitch = props.globals.getNode("/controls/fuel/switch-position");
}

fuel_switch = func {

node = props.globals.getNode("/consumables/fuel/tank[0]/selected",0);
node.setBoolValue(0);
node = props.globals.getNode("/consumables/fuel/tank[1]/selected",0);
node.setBoolValue(0);
node = props.globals.getNode("/consumables/fuel/tank[2]/selected",0);
node.setBoolValue(0);

val = getprop("/controls/fuel/switch-position");
      test = 1 + val;
      if(test > 2){test= -1};
setprop("/controls/fuel/switch-position",test);
if(test > -1){
node = props.globals.getNode("/consumables/fuel/tank[" ~ test ~ "]/selected",0);
node.setBoolValue(1);
 }
}

starter = func {
starter_power = getprop("/systems/electrical/volts");
if(starter_power == nil){starter_power = 0;}
if (arg[0] == 1){
if( starter_power > 5.0){ setprop("/controls/engines/engine[0]/starter",1);}
}else{ setprop("/controls/engines/engine[0]/starter",0);}
}

pitot_heat_switch = func {
toggle=getprop("/controls/anti-ice/pitot-heat");
toggle=1-toggle;
setprop("/controls/anti-ice/pitot-heat",toggle);
}

landing_light_switch = func {
toggle=getprop("/controls/switches/landing-light");
toggle=1-toggle;
setprop("/controls/switches/landing-light",toggle);
}

nav_light_switch = func {
toggle=getprop("/controls/switches/nav-lights");
toggle=1-toggle;
setprop("/controls/switches/nav-lights",toggle);
}

PropIncrease = func {
val = getprop("/controls/engines/engine[0]/propeller-pitch");
if(val < 1.00){val = val + 0.02;
setprop("/controls/engines/engine[0]/propeller-pitch",val);
   }
}
PropDecrease = func {
val = getprop("/controls/engines/engine[0]/propeller-pitch");
if(val > 0.00){val = val - 0.02;
setprop("/controls/engines/engine[0]/propeller-pitch",val);
   }
}


gforce = func{
    force = getprop("/accelerations/pilot-g");
if(force == nil) {force = 1.0;}
eyepoint = (0.66 - (force * 0.02));

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
