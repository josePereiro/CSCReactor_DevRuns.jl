@time begin
    using CSCReactor_jlOs
    # using CairoMakie
    using LibSerialPort
    using JSON
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0_utils.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    portname = "/dev/cu.usbmodem14201"
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# 
let
    _AIR_PUMP_PIN = PUMP_3_PIN
    _DIL_PUMP_PIN = PUMP_2_PIN
    _STIRREL_PIN = STIRREL_PIN
    _MEDIUM_OUT_PUMP_PIN = PUMP_1_PIN
    _LASER_PIN = CH1_LASER_PIN
    _LED1_PIN = CH1_VIAL_LED_PIN
    _LED2_PIN = CH1_CONTROL_LED_PIN
    
    _PULSE_DURATION = 50 # ms
    _PULSE_PERIOD = 81 # s

    # $INO:PIN-MODE:PIN:MODE%
    @time res = send_csvcmd(sp, "INO", "PIN-MODE", 
        _AIR_PUMP_PIN, OUTPUT,
        _DIL_PUMP_PIN, OUTPUT,
        _STIRREL_PIN, OUTPUT,
        _MEDIUM_OUT_PUMP_PIN, OUTPUT,
        _LASER_PIN, OUTPUT,

        _LED1_PIN, INPUT_PULLUP,
        _LED2_PIN, INPUT_PULLUP,
    )

    last_dil_pulse_time = 0

    while true
        try
            # medium out
            @time res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _MEDIUM_OUT_PUMP_PIN, 1, 300, 0;
            )
            # air in
            @time res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _AIR_PUMP_PIN, 1, 500, 0;
            )
            # stirring
            @time res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                _STIRREL_PIN, 1, 249, 0;
            )

            # non blocking sleep/ pumping
            for it in 1:10
                # If we need to pump
                if (time() - last_dil_pulse_time > _PULSE_PERIOD)
                    @info "PUMPED"
                    last_dil_pulse_time = time()
                    # stirring
                    @time res = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                        _DIL_PUMP_PIN, 1, _PULSE_DURATION, 0;
                    )
                end
                sleep(0.1)
            end

            @time send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 210);
            @time send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 210; log = false);
            sleep(0.4)

            @time global pkg1 = send_csvcmd(sp, "INO", "PULSE-IN", _LED1_PIN, 100)
            isempty(pkg1["done_ack"]) && continue
            val1 = parse(Int, pkg1["responses"][0]["data"][2])
            @show  val1

            @time pkg2 = send_csvcmd(sp, "INO", "PULSE-IN", _LED2_PIN, 100)
            isempty(pkg2["done_ack"]) && continue
            val2 = parse(Int, pkg2["responses"][0]["data"][2])
            @show  val2

            @time send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 0);
            @time send_csvcmd(sp, "INO", "ANALOG-WRITE", _LASER_PIN, 0; log = false);


        catch err
            @error err
        end
    end
    nothing;
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-