var ADFmode=nil;
var Wswitch = 0;
var FLevel = 0;
var Fswitch=0;
var FDM = "";
var T1=0;
var WLH_lvl = props.globals.initNode("/consumables/fuel/tank[4]/level-lbs");
var WRH_lvl = props.globals.initNode("/consumables/fuel/tank[5]/level-lbs");
var Wlvr=0;
var density=6.01;
var PSI =0;
var Rn=0;
var FPSI=0;
var Tank0=props.globals.getNode("/consumables/fuel/tank[0]/level-lbs",1);
##################################

setlistener("/sim/signals/fdm-initialized", func {
    ADFmode=props.globals.initNode("instrumentation/adf/mode-knob",0,"INT");
    settimer(check_doors,2);
    print("dhc2.nas loaded");
});

setlistener("/engines/engine/running", func(smk){
    if(smk.getBoolValue()){
        Rn=1;
        setprop("engines/engine/firing",1);
        settimer(smoke_off,7);
    }else Rn=0;
},1,0);

setlistener("sim/current-view/internal", func(snd){
    if(snd.getBoolValue()){
        setprop("sim/sound/Nvolume",0.2);
    }else setprop("sim/sound/Nvolume",1);
},1,0);

var smoke_off=func{setprop("engines/engine/firing",0);}

var wingtanks=func(sc,pos){
    Flevel = getprop("/consumables/fuel/tank[1]/level-lbs");
    if(Flevel<210.0){
        if(pos==1){
            WLH_lvl=getprop("/consumables/fuel/tank[4]/level-lbs");
            if(WLH_lvl>0.1){
                setprop("/consumables/fuel/tank[4]/level-lbs",WLH_lvl - (sc*0.2));
                setprop("/consumables/fuel/tank[1]/level-lbs",Flevel + (sc*0.2));
            }var PSI =0;
         }elsif(pos==2){
            WLH_lvl=getprop("/consumables/fuel/tank[4]/level-lbs");
            WRH_lvl=getprop("/consumables/fuel/tank[5]/level-lbs");
            if(WLH_lvl>0.1){
                setprop("/consumables/fuel/tank[4]/level-lbs",WLH_lvl - (sc*0.1));
                setprop("/consumables/fuel/tank[1]/level-lbs",getprop("/consumables/fuel/tank[1]/level-lbs") + (sc*0.1));
            }
            if(WRH_lvl>0.1){
                setprop("/consumables/fuel/tank[5]/level-lbs",WRH_lvl - (sc*0.1));
                setprop("/consumables/fuel/tank[1]/level-lbs",getprop("/consumables/fuel/tank[1]/level-lbs") + (sc*0.1));
            }
        }elsif(pos==3){
            WRH_lvl=getprop("/consumables/fuel/tank[5]/level-lbs");
            if(WRH_lvl>0.1){
                setprop("/consumables/fuel/tank[5]/level-lbs",WRH_lvl - (sc*0.2));
                setprop("/consumables/fuel/tank[1]/level-lbs",Flevel + (sc*0.2));
            }
    
        }
    }
}

var maintanks=func(sc){
    T1=getprop("/consumables/fuel/tank["~Fswitch~"]/level-lbs");
    if(T1>0.0){
        setprop("/consumables/fuel/tank["~Fswitch~"]/level-lbs",T1-PSI);
        var TTLflow=(FPSI+PSI)+((0.1-FPSI)*0.2);
        Tank0.setValue(TTLflow);
    }
}

var cht=func{
    var ct=getprop("engines/engine/cht-degf") or 0;
    var tgt = 150 +(getprop("engines/engine/rpm")*0.05);
    if(Rn) ct+=0.25 else ct-=0.05;
    if(ct>tgt)ct=tgt;
    if(ct<0)ct=0;
    setprop("engines/engine/cht-degf",ct);
    settimer(cht,1);
    }


var fuelloop = func{

    Fswitch=getprop("controls/fuel/switch-position");
    FPSI=Tank0.getValue();
    var sec=getprop("sim/time/delta-sec") or 0;
    var gph=getprop("/engines/engine/fuel-flow-gph") or 0;
    PSI = ((gph*0.00027777)*sec)*density;
    PSI =PSI*Rn;
    #print("PPS :",PSI,"  PSI :",FPSI);

    if(FDM=="yasim"){
            FPSI=FPSI-PSI;
            setprop("/consumables/fuel/tank[0]/level-lbs",FPSI);
    }

    Wswitch = getprop("/controls/fuel/wing-tank-position");
    if(Wswitch>0){wingtanks(sec,Wswitch);}

    if(Fswitch and Rn){maintanks(sec);}

if(FPSI<0.025)setprop("engines/engine/out-of-fuel",1) else setprop("engines/engine/out-of-fuel",0);

    settimer(fuelloop,0);
}

var check_doors = func{
    var vlc=getprop("velocities/airspeed-kt");
    if(vlc>25){
    setprop("controls/doors/open[0]",0);
    setprop("controls/doors/open[1]",0);
    setprop("controls/doors/open[2]",0);
    setprop("controls/doors/open[3]",0);
    }
    settimer(check_doors,0);
}
