
setlistener("/sim/signals/fdm-initialized", func {
    settimer(check_doors,2);
});

setlistener("/engines/engine/running", func(smk){
    if(smk.getBoolValue()){
        setprop("engines/engine/firing",1);
        settimer(smoke_off,7);
    };
},1,0);

setlistener("sim/current-view/internal", func(snd){
    if(snd.getBoolValue()){
        setprop("sim/sound/Nvolume",0.2);
    }else setprop("sim/sound/Nvolume",1);
},1,0);

var smoke_off=func{setprop("engines/engine/firing",0);}

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
