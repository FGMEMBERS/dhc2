fswitch = nil;
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
      if(test > 3){test=0};
setprop("/controls/fuel/switch-position",test);
if(test == 1){
node = props.globals.getNode("/consumables/fuel/tank[0]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[0]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
if(test == 2){
node = props.globals.getNode("/consumables/fuel/tank[1]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[1]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
if(test == 3){
node = props.globals.getNode("/consumables/fuel/tank[2]/selected",0);
node.setBoolValue(1);
if(getprop("/consumables/fuel/tank[2]/level-gal_us")>0.01){
node = props.globals.getNode("/engines/engine/out-of-fuel",0);
node.setBoolValue(0);} 
 }
}


batt_switch = func {
toggle=getprop("/controls/electric/battery-switch");
toggle=1-toggle;
setprop("/controls/electric/battery-switch",toggle);
}

alt_switch = func {
toggle=getprop("/controls/electric/engine/generator");
toggle=1-toggle;
setprop("/controls/electric/engine/generator",toggle);
}

f_pump_switch = func {
toggle=getprop("/controls/engines/engine/fuel-pump");
toggle=1-toggle;
setprop("/controls/engines/engine/fuel-pump",toggle);
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

instr_light_switch = func {
toggle1=getprop("/controls/switches/instr-lights");
toggle1=1-toggle1;
setprop("/controls/switches/instr-lights",toggle1);
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
rock = -0.25;
    force = getprop("/accelerations/pilot-g");
    sideslip = getprop("/orientation/side-slip-rad");
if(force == nil) {force = 1.0;}
if(sideslip == nil) {sideslip = 0.0;}
eyepoint = (0.66 - (force * 0.01));

if(getprop("/gear/gear/wow") == 0){
rock = (-0.25 - (sideslip * 0.1));}
if(getprop("/sim/current-view/view-number") < 1){
setprop("/sim/current-view/y-offset-m",eyepoint);
setprop("/sim/current-view/x-offset-m",rock);
  }
settimer(gforce, 0);
}
settimer(gforce, 0);