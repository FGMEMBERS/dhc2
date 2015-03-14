var swt={batt:0,gen:0,instr:0,lnd:0,nav:0,starter:0};
var bus={pwr:0,norm:0};
var stp=0;
var outPut = "systems/electrical/outputs/";
var nav_light_sw=props.globals.initNode("controls/lighting/nav-lights", 0,"BOOL");
aircraft.light.new("controls/lighting/strobe", [0.05, 1.30], nav_light_sw);
aircraft.light.new("controls/lighting/beacon", [1.0, 1.0], nav_light_sw);
var Batt=24;
#####################################
setlistener("/sim/signals/fdm-initialized", func {
    settimer(update_electrical,5);
    print("Electrical.nas loaded");
});

setlistener("/controls/electric/battery-switch", func(bt){
    swt.batt=bt.getValue() or 0;
},1,0);

setlistener("/controls/electric/engine/generator", func(gen){
    swt.gen=gen.getValue() or 0;
},1,0);

setlistener("/controls/lighting/instrument-lights", func(instr){
    swt.instr=instr.getValue() or 0;
},1,0);

setlistener("/controls/lighting/landing-lights", func(lnd){
    swt.lnd=lnd.getValue() or 0;
},1,0);

setlistener("/controls/lighting/nav-lights", func(nav){
    swt.nav=nav.getValue() or 0;
},1,0);

setlistener("/controls/electric/starter-switch", func(strtr){
    swt.starter=strtr.getValue() or 0;
},1,0);

update_lights = func{
    setprop(outPut~"instrument-lights",bus.norm* swt.instr);
    setprop(outPut~"beacon",bus.norm*getprop("controls/lighting/beacon/state"));
    setprop(outPut~"strobe",bus.norm*getprop("controls/lighting/strobe/state"));
    setprop(outPut~"landing-lights",bus.norm * swt.lnd);
    setprop(outPut~"nav-lights",bus.norm * swt.nav);
    setprop("controls/engines/engine/starter",bus.norm* swt.starter);

    if(getprop("sim/current-view/internal")){
        setprop("/sim/rendering/als-secondary-lights/use-landing-light",bus.norm * swt.lnd);
    }else setprop("/sim/rendering/als-secondary-lights/use-landing-light",0);
}

update_avn = func{
    setprop(outPut~"comm",bus.pwr);
    setprop(outPut~"comm[1]",bus.pwr);
    setprop(outPut~"nav",bus.pwr);
    setprop(outPut~"nav[1]",bus.pwr);
    setprop(outPut~"DG",bus.pwr);
    setprop(outPut~"adf",bus.pwr);
    setprop(outPut~"dme",bus.pwr);
    setprop(outPut~"turn-coordinator",bus.pwr);
}

update_electrical = func {
    var sc=getprop("sim/time/delta-sec");
    var rpm = getprop("engines/engine/rpm");
    if(swt.starter)Batt-=(sc*0.5);
    bus.pwr = Batt * swt.batt;
    if(swt.gen and getprop("engines/engine/rpm") >500){
    bus.pwr=28;
    if(Batt<24)Batt+=(sc*0.01);
    }else Batt-=(sc*0.003);
    setprop("systems/electrical/volts",bus.pwr);
    if(bus.pwr>0)bus.norm=1 else bus.norm=0;
    setprop("systems/electrical/power-norm",bus.norm);
    update_lights();
    update_avn();

settimer(update_electrical, 0);
}
