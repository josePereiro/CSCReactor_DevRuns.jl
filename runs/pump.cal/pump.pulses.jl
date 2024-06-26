@time begin
    using CSCReactor_jlOs
    using CairoMakie
    using LibSerialPort
    using Statistics
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
    portname = "/dev/tty.usbmodem14101"
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
# PUMP CAL ROUTINE
# _t = @async 
let
    scale = 500 / 500 # relativo al pulse duration
    npulses = ceil(Int, 50 / scale)
    # delay = max(0.1, 0.3 * scale)
    delay = 0.05
    power = 255
    pulse_duration = ceil(Int, 500 * scale) # ms
    exectime = @elapsed for pulsei in 1:npulses
        @show pulsei
        res = send_csvcmd(sp, "INO", "ANALOG-PULSE", 
            PUMP_PWMPIN, 
            power, # POWER 
            0, 
            pulse_duration,    # PULSE DURATION (ms)
            tout = 20
        )
        @assert haskey(res, "done_ack")
        sleep(delay) # stability
    end
    # params
    @show scale
    @show npulses
    @show delay
    @show power
    @show pulse_duration
    @show exectime
    nothing
end
nothing
# schedule(_t, InterruptException(), error=true)

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# DATA COLECCTION
let
    # delay = 0.3
    # power = 255
    # pulse_duration = 500 # ms
    global dat = Dict(
        "npulses_dat" => [
            50, 50, 50, 50, 
            50, 50, 50, 50, 
            50, 50, 50, 50, 
            50, 50, 50, 50, 
            250, 250, 250, 250, 
            500, 500, 500, 500, 
            125, 125, 125, 125, 
            84, 84, 84, 84, 
            1, 1, 1, 1,
            2500, 2500, 2500, 2500, 
            2, 2, 2, 2,
            10, 10, 10, 10, 
            5000, 5000, 5000, 
            8334, 8334, 8334, 
        ], 
        "delay_dat" => [
            0.3, 0.3, 0.3, 0.3, 
            0.1, 0.1, 0.1, 0.1,
            0.0, 0.0, 0.0, 0.0, 
            0.2, 0.2, 0.2, 0.2, 
            0.06, 0.06, 0.06, 0.06, 
            0.03, 0.03, 0.03, 0.03, 
            0.12, 0.12, 0.12, 0.12, 
            0.18, 0.18, 0.18, 0.18, 
            0.0, 0.0, 0.0, 0.0,
            0.1, 0.1, 0.1, 0.1, 
            0.1, 0.1, 0.1, 0.1, 
            0.1, 0.1, 0.1, 0.1, 
            0.1, 0.1, 0.1, 
            0.05, 0.05, 0.05,
        ], 
        "power_dat" => [
            255, 255, 255, 255, 
            255, 255, 255, 255,
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255, 255, 
            255, 255, 255,         
            255, 255, 255
        ], 
        "pulse_duration_dat" => [
            500, 500, 500, 500, 
            500, 500, 500, 500,
            500, 500, 500, 500, 
            500, 500, 500, 500, 
            100, 100, 100, 100, 
            50, 50, 50, 50, 
            200, 200, 200, 200, 
            300, 300, 300, 300, 
            25200, 25200, 25200, 25200, 
            10, 10, 10, 10, 
            12600, 12600, 12600, 12600, 
            2520, 2520, 2520, 2520, 
            5, 5, 5,
            3, 3, 3
        ], 
        "exectime_dat" => [
            42.665751525, 42.595814196, 42.609258609, 42.609679272, 
            32.575687369, 32.591687347, 32.563686522, 32.566628186,
            27.625145417, 27.589586069, 27.604217761, 27.689892306, 
            37.681894622, 37.73323615, 37.753414761, 37.750106303, 
            53.123831327, 53.474128619, 54.057132603, 53.975687445, 
            67.575916598, 67.511936533, 67.40644017, 67.247587389, 
            47.381613873, 47.090728141, 46.612981048, 46.558339795, 
            45.087373289, 44.807628611, 45.180785756, 44.82563457,
            1.056456, 1.12323, 1.073761213, 1.071972783, 1.747257649,
            460.963776726, 469.166815279, 472.233452753, 460.876935772, 
            1.3258763, 1.205983174, 1.206559046, 1.20747838, 
            26.247684422, 26.229375323, 26.238019873, 26.24506814, # fix tout issue
            954.086493156, 972.33987288, 948.299132432, 
            1121.491235852, 1124.2459351, 1120.968733061
        ], 
        "vol_dat" => [
            33.5, 34.0, 34.5, 34.0, 
            34.1, 34.5, 34.9, 34.9,
            34.5, 34.8, 34.9, 34.9, 
            35.0, 35.1, 35.0, 35.1, 
            34.5, 34.5, 34.6, 34.7, 
            33.0, 32.9, 33.0, 33.0, 
            35.8, 35.8, 36.0, 35.6, 
            36.0, 36.0, 36.0, 36.0, 
            35.5, 35.5, 35.6, 35.6, 
            30.0, 30.0, 30.0, 29.9, 
            36.0, 36.0, 36.0, 36.1, 
            36.0, 36.0, 36.0, 35.9, 
            25.0, 25.0, 25.0, 
            19.7, 19.6, 19.4, 
        ]
    )
    nothing
end

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-

# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    f = Figure()

    commom_layout = (;
        width = 200,
        height = 200,
    )

    ax = Axis(f[1,1];
        xlabel = "experiment", 
        ylabel = "rel value", 
        limits = (nothing, nothing, -0.05, 1.1), 
        yticks = -0.5:0.1:1.5, 
        commom_layout...
    )
    xs = eachindex(dat["pulse_duration_dat"])
    ys = dat["npulses_dat"]
    sidx = sortperm(ys)
    
    ys = dat["pulse_duration_dat"] .* dat["npulses_dat"]
    max_ys = maximum(ys)
    lines!(ax, xs, ys[sidx] ./ max_ys)
    scatter!(ax, xs, ys[sidx] ./ max_ys; label = "pump on time / $(max_ys) [ms]")
    
    ys = dat["vol_dat"]
    max_ys = maximum(ys)
    lines!(ax, xs, ys[sidx] ./ max_ys)
    scatter!(ax, xs, ys[sidx] ./ max_ys; label = "tot pumped vol / $(max_ys) [mL]")

    ys = dat["npulses_dat"]
    max_ys = maximum(ys)
    lines!(ax, xs, ys[sidx] ./ max_ys)
    scatter!(ax, xs, ys[sidx] ./ max_ys; label = "tot pulses / $(max_ys)")

    ys = dat["delay_dat"]
    max_ys = maximum(ys)
    # lines!(ax, xs, ys[sidx] ./ max_ys)
    scatter!(ax, xs, ys[sidx] ./ max_ys; label = "delay between pulses / $(max_ys) [ms]")

    # ys = dat["pulse_duration_dat"]
    # max_ys = maximum(ys)
    # lines!(ax, xs, ys[sidx] ./ max_ys)
    # scatter!(ax, xs, ys[sidx] ./ max_ys; label = "pulse duration / $(max_ys) [ms]")
    
    
    # axislegend(ax; position = :rb)
    Legend(f[1,2], ax, "", framevisible = true)

    ax = Axis(f[2,1];
        xlabel = "tot pulses (log scale)", 
        ylabel = "pomped volume", 
        limits = (nothing, nothing, -0.05, 1.1), 
        yticks = -0.5:0.1:1.5, 
        commom_layout...
    )

    xs = dat["npulses_dat"]
    ys = dat["vol_dat"]
    max_ys = maximum(ys)
    scatter!(ax, log10.(xs[sidx]), ys[sidx] ./ max_ys; label = "tot pumped vol / $(max_ys) [mL]")

    Legend(f[2,2], ax, "", framevisible = true)

    ax = Axis(f[3,1]; 
        xlabel = "pulse duration [ms] \n(log scale)", 
        ylabel = "vol per pulse [mL]\n(log scale)", 
        # limits = (nothing, nothing, -0.05, 1.1), 
        # yticks = -0.5:0.1:1.5
        commom_layout...
    )
    
    # xs = dat["npulses_dat"]
    xs = dat["pulse_duration_dat"]
    ys = dat["vol_dat"] ./ dat["npulses_dat"]
    max_ys = maximum(ys)
    scatter!(ax, log10.(xs[sidx]), log10.(ys[sidx]); 
        label = string(
            "- n: ", length(log10.(xs[sidx])), "\n",
            "- pearson: ", 
            round(Statistics.cor(log10.(xs[sidx]), log10.(ys[sidx])), 
                digits = 5
            ), "\n",
        )
    )

    Legend(f[3,2], ax, "", framevisible = true)

    resize_to_layout!(f)
    f

end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# Corves simulations
function _pump_period(wV, pV, tD)

    f = wV * tD # [mL/h] absolute flux
    ppm = f / pV # [pulses/h] absolute pulse rate
    ppm = ppm / 60 / 60 # [pulses/s]
    period = 1 / ppm # [s/pulse]
    return period
end
# ---.-.- ...- -- .--- . .- .-. . ..- .--.-
let
    pV = unique(sort(dat["vol_dat"] ./ dat["npulses_dat"]))[1] # [mL]
    @show pV
    wV = 25 # [mL]

    f = Figure()
    ax = Axis(f[1,1];
        title = string(
            "wV=", wV, " mL", "\n",
            "pV=", round(pV; sigdigits = 2), " mL",
        ),
        xlabel = "time (min)",
        ylabel = "pumped vol (mL)",
        limits = (nothing, nothing, -0.01, 0.1)
    )
    
    for wD in [0.01, 0.05, 0.1, 0.3, 0.4, 1.0]

        period = _pump_period(wV, pV, wD)
        @show period
        vol_ts = Float64[];
        vol = 1e-3
        last_pumped = 0
        simtime = 0
        dt = 1e-1
        # niters = ceil(Int, max(45, 3 * period) / dt)
        niters = 800
        @show niters
        # niters = 1e10
        # niters = 1e5
        @show niters
        for it in 1:niters
            if simtime - last_pumped > period
                last_pumped = simtime
                vol += pV
            end
            # vol > 0.05 && break
            push!(vol_ts, vol)
            simtime += dt
        end
        lines!(ax, eachindex(vol_ts) .* dt ./ 60, vol_ts; 
            label = "D=$(wD) (1/h)", 
            linewidth = 3
        )
    end
    Legend(f[1,2], ax, "", framevisible = true)
    f
end


