##
# DHC-2 electrical system.
##

# Initialize internal values
#

battery = nil;
alternator = nil;

last_time = 0.0;

vbus_volts = 0.0;
ebus1_volts = 0.0;
ebus2_volts = 0.0;

ammeter_ave = 0.0;

##
# Initialize the electrical system
#

init_electrical = func {
    print("Initializing Nasal Electrical System");
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

    setprop("/controls/electric/battery-switch", 0);
    setprop("/controls/electric/engine/generator", 0);
    setprop("/controls/switches/landing-light", 0);
    setprop("/controls/switches/nav-lights", 0);
    setprop("/controls/anti-ice/pitot-heat", 0);
    setprop("/controls/anti-ice/engine/carb-heat", 0);
    setprop("/controls/switches/instr-lights", 0);
    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 12.75,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    # print( "battery percent = ", me.charge_percent);
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}


AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/rpm",
            rpm_threshold : 600.0,
            ideal_volts : 28.0,
            ideal_amps : 60.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}


AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}


update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    update_virtual_bus( dt );

    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}



update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator_volts = alternator.get_output_volts();
    external_volts = 0.0;
    load = 0.0;

    # switch state
    master_bat = getprop("/controls/electric/battery-switch");
    master_alt = getprop("/controls/electric/engine/generator");

    # determine power source
    bus_volts = 0.0;
    power_source = nil;
    if ( master_bat ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }
    if ( master_alt and (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
    }
    if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
    }
    # print( "virtual bus volts = ", bus_volts );

    # starter motor
    starter_switch = getprop("/controls/engines/engine[0]/starter");
    starter_volts = 0.0;
    if ( starter_switch ) {
        starter_volts = bus_volts;
    }
    setprop("/systems/electrical/outputs/starter[0]", starter_volts);

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determins where it draws power from.)
    load += electrical_bus_1();
    load += electrical_bus_2();
    load += cross_feed_bus();
    load += avionics_bus_1();
    load += avionics_bus_2();

    # system loads and ammeter gauge
    ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        # normal load
        load += 15.0;

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    vbus_volts = bus_volts;

    return load;
}


electrical_bus_1 = func() {
    # we are fed from the "virtual" bus
    bus_volts = vbus_volts;
    load = 0.0;
    
    # Cabin Lights Power
    if ( getprop("/controls/circuit-breakers/cabin-lights-pwr") ) {
        setprop("/systems/electrical/outputs/cabin-lights", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/cabin-lights", 0.0);
    }

    # Instrument Power
    setprop("/systems/electrical/outputs/instr-ignition-switch", bus_volts);

    # Fuel Pump Power
    if ( getprop("/controls/engines/engine[0]/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    # Landing Light Power
    if ( getprop("/controls/switches/landing-light") ) {
        setprop("/systems/electrical/outputs/landing-light", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/landing-light", 0.0 );
    }


    # Flaps Power
    setprop("/systems/electrical/outputs/flaps", bus_volts);

    # register bus voltage
    ebus1_volts = bus_volts;

    # return cumulative load
    return load;
}


electrical_bus_2 = func() {
    # we are fed from the "virtual" bus
    bus_volts = vbus_volts;
    load = 0.0;

    # Turn Coordinator Power
    setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
  
    # Nav Lights Power
    if ( getprop("/controls/switches/nav-lights" ) ) {
        setprop("/systems/electrical/outputs/nav-lights", bus_volts);
        if ( bus_volts > 1.0 ) { load += 7.0; }
    } else {
        setprop("/systems/electrical/outputs/nav-lights", 0.0);
    }

    # Instrument Lights Power
    if ( getprop("/controls/switches/instr-lights" ) ) {
    setprop("/systems/electrical/outputs/instrument-lights", bus_volts);
} else {
    setprop("/systems/electrical/outputs/instrument-lights", 0.0);
    }
    setprop("/controls/lighting/instruments-norm", getprop("/systems/electrical/outputs/instrument-lights") * 0.041666);



    # Pitot Heat Power
    if ( getprop("/controls/anti-ice/pitot-heat" ) ) {
        setprop("/systems/electrical/outputs/pitot-heat", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/pitot-heat", 0.0);
    }
  
    # register bus voltage
    ebus2_volts = bus_volts;

    # return cumulative load
    return load;
}


cross_feed_bus = func() {
    # we are fed from either of the electrical bus 1 or 2
    if ( ebus1_volts > ebus2_volts ) {
        bus_volts = ebus1_volts;
    } else {
        bus_volts = ebus2_volts;
    }

    load = 0.0;

    setprop("/systems/electrical/outputs/annunciators", bus_volts);

    # return cumulative load
    return load;
}


avionics_bus_1 = func() {
    master_av = getprop("/controls/switches/master-avionics");
    bus_volts = ebus1_volts;
   load = 0.0;

    # HSI Power
    setprop("/systems/electrical/outputs/hsi", bus_volts);
  
    # Nav 1 Power
    setprop("/systems/electrical/outputs/nav[0]", bus_volts);

    # Com 1 Power
    setprop("/systems/electrical/outputs/comm[0]", bus_volts);

    # return cumulative load
    return load;
}


avionics_bus_2 = func() {
    master_av = getprop("/controls/switches/master-avionics");
        bus_volts = ebus2_volts;
    load = 0.0;

    # Com 2 Power
    setprop("/systems/electrical/outputs/comm[1]", bus_volts);

    # Transponder Power
    setprop("/systems/electrical/outputs/transponder", bus_volts);

     # ADF Power
    setprop("/systems/electrical/outputs/adf", bus_volts);

    # return cumulative load
    return load;
}


# Setup a timer based call to initialized the electrical system as
# soon as possible.
settimer(init_electrical, 0);
