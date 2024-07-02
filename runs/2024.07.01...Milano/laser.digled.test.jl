@time begin
    using CSCReactor_jlOs
    using CairoMakie
    using LibSerialPort
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
include("0_utils.jl")

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    # portname = "/dev/tty.usbmodem14101"
    portname = "/dev/cu.usbmodem14201"
    
    baudrate = 19200
    global sp = LibSerialPort.open(portname, baudrate)
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Setup
let
    send_csvcmd(sp, "INO", "PIN-MODE", 
        STIRREL_PIN, OUTPUT,
        # PUMP_1_PIN, OUTPUT,
        # PUMP_2_PIN, OUTPUT,
        # PUMP_3_PIN, OUTPUT,
        # PUMP_4_PIN, OUTPUT,

        CH1_LASER_PIN, OUTPUT,
        CH1_VIAL_LED_PIN, INPUT_PULLUP,
        CH1_CONTROL_LED_PIN, INPUT_PULLUP
    )
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DIGITAL LEDS
let
    LASER_PWMPIN = CH1_LASER_PIN
    STIRREL_PWMPIN = STIRREL_PIN
    LED1_INPIN = CH1_CONTROL_LED_PIN
    LED2_INPIN = CH1_VIAL_LED_PIN

    try
        global led1_vals, led2_vals, laser_pwms = Float64[], Float64[], Float64[]

        plot_frec = 1
        plot_last_time = 0
        
        laser_pwm = 0
        laser_pwm1 = 255
        
        stirrel_frec = 0.5
        stirrel_last_time = 0

        while true
            # control laser
            @show laser_pwm
            laser_pwm = mod(laser_pwm + 1, laser_pwm1)
            @time send_csvcmd(sp, "INO", "ANALOG-WRITE", LASER_PWMPIN, laser_pwm);

            # stirrel
            if time() - stirrel_last_time > stirrel_frec
                # @time pkg1 = send_csvcmd(sp, "INO", "ANALOG-PULSE", STIRREL_PWMPIN, 180, 0, 250)
                # $INO:DIGITAL-C-PULSE:PIN:VAL0:TIME:[VAL1]%
                @time pkg1 = send_csvcmd(sp, "INO", "DIGITAL-S-PULSE", 
                    STIRREL_PWMPIN, 1, 249, 0
                )
                stirrel_last_time = time()
                sleep(0.5) # relax
            end

            # read sensors 1
            @time pkg1 = send_csvcmd(sp, "INO", "PULSE-IN", LED1_INPIN, 100)
            isempty(pkg1["done_ack"]) && continue
            val1 = parse(Int, pkg1["responses"][0]["data"][2])

            # read sensors 2
            @time pkg2 = send_csvcmd(sp, "INO", "PULSE-IN", LED2_INPIN, 100)
            isempty(pkg2["done_ack"]) && continue
            val2 = parse(Int, pkg2["responses"][0]["data"][2])
            
            # push
            push!(led1_vals, val1)
            push!(led2_vals, val2)
            push!(laser_pwms, laser_pwm)

            # plot
            if time() - plot_last_time > plot_frec
                plot_last_time = time()
                
                isempty(led1_vals) && continue
                isempty(led2_vals) && continue
                isempty(laser_pwms) && continue

                f = Figure()
                
                limits = (nothing, nothing, 0, nothing)
                ax = Axis(f[1, 1]; limits, ylabel = "laser power")
                scatter!(ax, eachindex(laser_pwms), laser_pwms; color = :red)
                
                ax = Axis(f[2, 1]; limits, xlabel = "time", ylabel = "led read")
                scatter!(ax, eachindex(led1_vals), led1_vals; color = :red)
                scatter!(ax, eachindex(led2_vals), led2_vals; color = :blue)
                
                ax = Axis(f[3, 1]; limits, xlabel = "led read", ylabel = "laser power")
                scatter!(ax, led1_vals, laser_pwms; color = :red)
                scatter!(ax, led2_vals, laser_pwms; color = :blue)

                display(f)
            end
        end
    catch err; 
        @error err
        err isa InterruptException || rethrow(err)
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PULSESES
# stirrel       D8
# pump          D12
let
    # send_csvcmd(sp, "INO", "ANALOG-PULSE", STIRREL_PWMPIN, 250, 0, 5)
    send_csvcmd(sp, "INO", "ANALOG-PULSE", 
        PUMP_PWMPIN, 
        255, # POWER 
        0, 
        1    # PULSE DURATION (ms)
    )
    nothing
end