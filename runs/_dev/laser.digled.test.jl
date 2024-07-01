@time begin
    using CSCReactor_jlOs
    using CairoMakie
    using LibSerialPort
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PIN LAYOUT
# led1 (A8)
LED1_INPIN = 8
# led2 (A12, D37)
LED2_INPIN = 37
# laser (D5)
LASER_PWMPIN = 5
# stirrel (D8)
STIRREL_PWMPIN = 8
# pump (D11)
PUMP_PWMPIN = 11


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
    # $INO:PIN-MODE:PIN:MODE%
    OUTPUT = 1
    INPUT_PULLUP = 2
    send_csvcmd(sp, "INO", "PIN-MODE", PUMP_PWMPIN, OUTPUT)
    send_csvcmd(sp, "INO", "PIN-MODE", LASER_PWMPIN, OUTPUT)
    send_csvcmd(sp, "INO", "PIN-MODE", STIRREL_PWMPIN, OUTPUT)
    send_csvcmd(sp, "INO", "PIN-MODE", LED2_INPIN, INPUT_PULLUP)
    
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DIGITAL LEDS
let
    try
        global led_vals, laser_pwms = Float64[], Float64[]

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
                @time pkg1 = send_csvcmd(sp, "INO", "ANALOG-PULSE", STIRREL_PWMPIN, 180, 0, 250)
                stirrel_last_time = time()
                sleep(0.3) # relax
            end

            # read sensors
            @time pkg1 = send_csvcmd(sp, "INO", "PULSE-IN", LED2_INPIN, 100)
            isempty(pkg1["done_ack"]) && continue
            val = parse(Int, pkg1["responses"][0]["data"][2])

            # Old sensor
            # @time pkg1 = send_csvcmd(sp, "INO", "ANALOG-READ", 12)
            # isempty(pkg1["done_ack"]) && continue
            # val = parse(Int, pkg1["responses"][0]["data"][2])
            
            # push
            push!(led_vals, val)
            push!(laser_pwms, laser_pwm)

            # plot
            if time() - plot_last_time > plot_frec
                plot_last_time = time()
                
                isempty(led_vals) && continue
                isempty(laser_pwms) && continue

                f = Figure()
                
                limits = (nothing, nothing, 0, nothing)
                ax = Axis(f[1, 1]; limits, ylabel = "laser power")
                scatter!(ax, eachindex(laser_pwms), laser_pwms; color = :red)
                
                ax = Axis(f[2, 1]; limits, xlabel = "time", ylabel = "led read")
                scatter!(ax, eachindex(led_vals), led_vals; color = :blue)
                
                ax = Axis(f[3, 1]; limits, xlabel = "led read", ylabel = "laser power")
                scatter!(ax, led_vals, laser_pwms; color = :black)

                display(f)
            end
        end
    catch err; end
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