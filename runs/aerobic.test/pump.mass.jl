@time begin
    using CSCReactor_jlOs
    using CairoMakie
    using LibSerialPort
    using Statistics
    using FFTW
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
STIRREL_PIN = 8
# (D11)
PUMP_FRESH_MEDIUM_PIN = 29
# 
PUMP_VIAL_MEDIUM_PIN = 43
# 
PUMP_AIR_PIN = 11
nothing

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    # portname = "/dev/cu.usbmodem14101"
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
    res = send_csvcmd(sp, "INO", "PIN-MODE", PUMP_FRESH_MEDIUM_PIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", PUMP_VIAL_MEDIUM_PIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", PUMP_AIR_PIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", LASER_PWMPIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", STIRREL_PIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", LED2_INPIN, INPUT_PULLUP)
    @assert haskey(res, "done_ack")
    
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# RUN
let
    for it in 1:500
        @show it
        try
            pulse_duration = 50
            res = send_csvcmd(sp, "INO", "ANALOG-PULSE", 
                PUMP_FRESH_MEDIUM_PIN, 
                200, 0, 
                pulse_duration;    # PULSE DURATION (ms)
                tout = 20
            )
            @assert haskey(res, "done_ack")

            pulse_duration = 1000
            res = send_csvcmd(sp, "INO", "DIGITAL-PULSE", 
                PUMP_VIAL_MEDIUM_PIN, 
                1, 0, 
                pulse_duration;    # PULSE DURATION (ms)
                tout = 20
            )
            @assert haskey(res, "done_ack")
            
            pulse_duration = 500
            res = send_csvcmd(sp, "INO", "DIGITAL-PULSE", 
                # STIRREL_PIN, 
                PUMP_AIR_PIN, 
                1, 0, 
                pulse_duration;    # PULSE DURATION (ms)
                tout = 20
            )
            @assert haskey(res, "done_ack")

            pulse_duration = 300
            res = send_csvcmd(sp, "INO", "ANALOG-PULSE", 
                STIRREL_PIN, 
                200, 0, 
                pulse_duration;    # PULSE DURATION (ms)
                tout = 20
            )
            @assert haskey(res, "done_ack")
            sleep(0.5)
        catch e
            e isa InterruptException && break
            rethrow(e)
        end
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    dat = [
        Dict(
            "num.pulses" => [
                500, 500, 500
            ],
            "pump.fresh.duration" => [
                50, 50, 50, 
            ], # ms
            "pump.stirrel.duration" => [
                300, 300, 300, 
            ], # ms
            "pump.stirrel.power" => [
                200, 200, 200
            ], # ms
            "pump.vial.duration" => [
                1000, 1000, 1000
            ], # ms
            "pump.air.duration" => [
                500, 500, 500
            ], # ms
            "tot.vol" => [
                35.0, 34.6, 35.0
            ], # mL
        ),
    ]
end