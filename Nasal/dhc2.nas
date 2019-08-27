
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

# For use by start-up checklist. We run starter until engine starts or a
# timeout expires.
#
var run_starter = func() {
    printf("run_starter()...");
    var timer = nil;
    var listener = nil;
    done = func() {
        timer.stop();
        removelistener(listener);
        setprop("/controls/electric/starter-switch", 0);
    }
    callback_running = func() {
        if (getprop("/engines/engine/running") == 1) {
            printf("run_starter(): engine is running");
            done();
        }
    };
    callback_timeout = func() {
        printf("run_starter(): timeout");
        done();
    }
    timer = maketimer(15, callback_timeout);
    listener = setlistener("/engines/engine/running", callback_running);
    timer.start();
    setprop("/controls/electric/starter-switch", 1);
}
