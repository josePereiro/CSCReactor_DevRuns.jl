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
STIRREL_PWMPIN = 8
# pump (D11)
PUMP_PWMPIN = 11

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    portname = "/dev/cu.usbmodem14101"
    # portname = "/dev/tty.usbmodem14101"
    # portname = "/dev/cu.usbmodem14201"
    
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
    res = send_csvcmd(sp, "INO", "PIN-MODE", PUMP_PWMPIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", LASER_PWMPIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", STIRREL_PWMPIN, OUTPUT)
    @assert haskey(res, "done_ack")
    res = send_csvcmd(sp, "INO", "PIN-MODE", LED2_INPIN, INPUT_PULLUP)
    @assert haskey(res, "done_ack")
    
    nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _pump_pulse(pulse_duration, power = 255)
    res = send_csvcmd(sp, "INO", "ANALOG-PULSE", 
        PUMP_PWMPIN, 
        power, # POWER 
        0, 
        pulse_duration,    # PULSE DURATION (ms)
        tout = 20
    )
    @assert haskey(res, "done_ack")
    return nothing
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# PUMP CAL ROUTINE
let 
    global dat = [
        Dict(
            "pulse_batch" => 1,
            "pulse_duration" => 1000,
            "mass" => [
                1.38, 2.82, 4.20, 5.61, 7.06, 8.48, 
                9.92, 11.32, 12.77, 14.23, 15.64, 17.06, 18.51, 
                19.93, 21.38, 22.83, 24.28, 25.72, 27.18, 28.61, 
                30.09, 31.52, 32.99, 34.38, 35.83, 37.29, 38.73, 40.18, 
                41.62, 43.07, 44.52, 45.99, 47.40
            ], 
            "final_vol" => 48.0
        ), 
        Dict(
            "pulse_batch" => 1,
            "pulse_duration" => 500,
            "mass" => [
                0.76, 1.47, 2.21, 2.99, 3.67, 4.38, 5.09, 5.80, 
                6.52, 7.24, 7.99, 8.67, 9.40, 10.12, 10.85, 11.57, 
                12.28, 13.00, 13.72, 14.43, 15.15, 15.88, 16.59, 17.33, 
                18.01, 18.75, 19.47, 20.19, 20.91, 21.62, 22.36, 23.07, 
                23.80, 24.50, 25.23, 25.94, 26.66, 27.39, 28.11, 28.84, 
                29.56, 30.30, 31.01, 31.74, 32.46, 33.19, 33.91, 34.62, 
                35.34, 36.06, 36.80, 37.49, 38.20, 38.93, 39.65, 40.35, 
                41.09, 41.81, 42.53, 43.23, 43.98, 44.68, 45.40, 46.11, 
                46.86, 47.40
            ], 
            "final_vol" => 48.0
        ), 
        Dict(
            "pulse_batch" => 10,
            "pulse_duration" => 3,
            "mass" => [
                 75.66, 75.71, 75.71, 75.71, 75.73, 75.78, 75.81, 75.81, 75.81, 75.85, 
                 75.85, 75.85, 75.88, 75.91, 75.93, 75.93, 75.93, 75.99, 76.04, 76.04, 
                 76.04, 76.06, 76.10, 76.13, 76.13, 76.15, 76.20, 76.20, 76.20, 76.20, 
                 76.22, 76.22, 76.22, 76.22, 76.25, 76.30, 76.30, 76.30, 76.32, 76.38, 
                 76.38, 76.38, 76.38, 76.42, 76.42, 76.42, 76.45, 76.49, 76.51, 76.51, 
                 76.53, 76.58, 76.61, 76.61, 76.61, 76.66, 76.68, 76.70, 76.70, 76.73, 
                 76.78, 76.78, 76.78, 76.81, 76.86, 76.86, 76.86, 76.86, 76.89, 76.92, 
                 76.92, 76.94, 76.99, 77.00, 77.04, 77.04, 77.04, 77.04, 77.04, 77.04, 
                 77.06, 77.11, 77.11, 77.11, 77.13, 77.19, 77.19, 77.19, 77.22, 77.27, 
                 77.27, 77.27, 77.29, 77.35, 77.35, 77.35, 77.35, 77.38, 77.42, 77.42, 
                 77.42, 77.45, 77.50, 77.50, 77.50, 77.52, 77.57, 77.57, 77.59, 77.66, 
                 77.66, 77.66, 77.68, 77.73, 77.75, 77.75, 77.75, 77.78, 77.83, 77.83, 
                 77.83, 77.83, 77.86, 77.89, 77.89, 77.91, 77.94, 77.96, 77.96, 77.98, 
                 78.03, 78.06, 78.06, 78.08, 78.13, 78.15, 78.15, 78.17, 78.20, 78.23, 
                 78.25, 78.25, 78.25, 78.28, 78.30, 78.30, 78.33, 78.38, 78.40, 78.40, 
                 78.40, 78.42, 78.47, 78.47, 78.47, 78.47, 78.49, 78.52, 78.52, 78.52, 
                 78.54, 78.59, 78.59, 78.59, 78.62, 78.64, 78.64, 78.64, 78.69, 78.71, 
                 78.74, 78.74, 78.76, 78.78, 78.81, 78.81, 78.84, 78.88, 78.90, 78.90, 
                 78.90
            ],
            "final_vol" => NaN
        ), 
        # Dict(
        #     "pulse_duration" => 1000,
        #     "mass" => [], 
        #     "final_vol" => 0.0
        # ), 
    ]
    for it in 1:dat[end]["pulse_batch"]
        _pump_pulse(dat[end]["pulse_duration"])
        sleep(0.1)
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-

function _plt_spectro!(f, fpos,  ys; 
        axis_kwargs = (;),
        plt_kwargs = (;),
    )

    fs = 1 / length(ys)  # Sampling frequency (Hz)

    # Step 3: Compute the FFT of the ys
    n = length(ys)  # Number of samples
    signal_fft = fft(ys)

    # Step 4: Extract frequency and amplitude information
    frequencies = (0:n-1) .* (fs / n)  # Frequency vector
    amplitudes = abs.(signal_fft) / n  # Amplitude spectrum (normalize by n)

    # Since FFT produces symmetrical results, we take the first half
    half_n = div(n, 2)
    frequencies = frequencies[2:half_n]
    amplitudes = 2 .* amplitudes[2:half_n]

    # Step 5: Plot the frequency vs amplitude
    ax = Axis(f[fpos...]; 
        xlabel = "Frequency (AU)", 
        ylabel = "Amplitude (AU)", 
        # limites = ()
        # show_xaxis = false
        axis_kwargs...
    )
    plt = lines!(ax, frequencies, amplitudes; plt_kwargs...)
    hidedecorations!(ax; label = false, ticks = false)
    f
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    f = Figure()
    dati = dat[3]
    ax = Axis(f[1,1]; 
        title = string(
            "pulse_duration = ", dati["pulse_duration"], " [ms]", "\n",
            "pulse_batch = ", dati["pulse_batch"], 
        ),
        xlabel = "num pulses",
        ylabel = "pumped mass [g]",
        limits = (nothing, nothing, -0.01, nothing), 
        width = 500, 
        height = 200, 
    )

    xs = eachindex(dati["mass"]) .* dati["pulse_batch"]
    xs = xs .+ 1
    ys = dati["mass"] 
    ys = ys .- minimum(ys)
    ys = diff(ys)
    push!(ys, last(ys))
    # ys = log10.(ys .+ 1e-3)

    lines!(ax, xs, ys; )

    _plt_spectro!(f, [2,1], ys; 
        axis_kwargs = (;
            width = 500, 
            height = 100, 
        ), 
        plt_kwargs = (;
            
        )
    )

    resize_to_layout!(f)
    f
end
