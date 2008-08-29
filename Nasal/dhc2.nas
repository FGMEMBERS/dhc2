aircraft.livery.init("Aircraft/dhc2/Models/Liveries");
var ViewNum = 0;
var Cvolume=props.globals.getNode("/sim/sound/DHC2/Cvolume",1);
var Ovolume=props.globals.getNode("/sim/sound/DHC2/Ovolume",1);
var rud_swingtime = 2;  # how long complete movement should last
var rud_target = 1;
var rud_prop =props.globals.getNode("/controls/gear/water-rudder-down",0);
var floats = 0;

#Engine sensors class 
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.air_temp = props.globals.getNode("environment/temperature-degc",1);
        m.eng = props.globals.getNode("engines/engine["~eng_num~"]",1);
        m.running = m.eng.getNode("running",1);
        m.condition = props.globals.getNode("controls/engines/engine["~eng_num~"]/condition",1);
        m.cutoff = props.globals.getNode("controls/engines/engine["~eng_num~"]/cutoff",1);
        m.mixture = props.globals.getNode("controls/engines/engine["~eng_num~"]/mixture",1);
        m.mixture_lever = props.globals.getNode("controls/engines/engine["~eng_num~"]/mixture-lever",1);
        m.mixture_lever.setDoubleValue(1.0);
        m.rpm = m.eng.getNode("rpm",1);
        m.oil_temp=m.eng.getNode("oil-temp-c",1);
        m.oil_temp.setDoubleValue(m.air_temp.getValue());
        m.oil_psi=m.eng.getNode("oil-pressure-psi",1);
        m.oil_psi.setDoubleValue(0);
        m.fuel_psi=m.eng.getNode("fuel-psi-norm",1);
        m.fuel_psi.setDoubleValue(0);
        m.fuel_out=m.eng.getNode("out-of-fuel",1);
        m.fuel_out.setBoolValue(0);
        m.fuel_switch=props.globals.getNode("controls/fuel/switch-position",1);
        m.fuel_switch.setIntValue(-1);
        m.hpump=props.globals.getNode("systems/hydraulics/pump-psi["~eng_num~"]",1);
        m.hpump.setDoubleValue(0);
        
    return m;
    },
#### update ####
    update : func{
        me.mixture.setValue(me.mixture_lever.getValue());
        var hpsi =me.rpm.getValue();
        var fpsi =me.fuel_psi.getValue();
        var oilpsi=hpsi * 0.001;
        if(oilpsi>0.7)oilpsi =0.7;
        me.oil_psi.setValue(oilpsi);
        if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
        var OT= me.oil_temp.getValue();
        var rpm = me.rpm.getValue();
        if(OT < rpm)OT+=0.01;
        if(OT > rpm)OT-=0.001;
        me.oil_temp.setValue(OT);
        var fpVolts =getprop("systems/electrical/outputs/fuel-pump");
        if(fpVolts==nil)fpVolts=0;
        if(fpVolts>5){
            if(fpsi<0.5000)fpsi += 0.01;
        }else{
            if(fpsi>0.000) fpsi -= 0.01;
        }
        me.fuel_psi.setValue(fpsi);
        if(fpsi < 0.2){
            me.mixture.setValue(fpsi);
        }
    },

    fuel_select : func (sw){
        var position=me.fuel_switch.getValue();
        position +=sw;
        if(position > 2)position -=4;
        if(position < -1)position +=4;
        me.fuel_switch.setValue(position);
        setprop("/consumables/fuel/tank[0]/selected",0);
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[2]/selected",0);
        if(position >= 0){
            setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
        };
        me.fuel_out.setValue(0);
    },

};
##################################

var WaspJr = Engine.new(0);

setlistener("/sim/signals/fdm-initialized", func {
    Cvolume.setValue(0.6);
    Ovolume.setValue(0.3);
    WaspJr.fuel_select(0);
    if(getprop("sim/aero")=="dhc2F")floats=1;
    settimer(update,1);
});

setlistener("/sim/current-view/view-number", func(vw){
    ViewNum = vw.getValue();
    if(ViewNum == 0){
        Cvolume.setValue(0.6);
        Ovolume.setValue(0.4);
    }else{
        Cvolume.setValue(0.1);
        Ovolume.setValue(1.0);
    }
},0,0);

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

var steering = func{
    if(getprop("/controls/gear/water-rudder-down") >= 0.9){
        setprop("/controls/gear/water-rudder-pos",getprop("/controls/flight/rudder"));
    }else{
        setprop("/controls/gear/water-rudder-pos",0);
    }
}

var update = func {
WaspJr.update();
   	if(floats ==1){
        steering();
    }
    settimer(update,0);
}

