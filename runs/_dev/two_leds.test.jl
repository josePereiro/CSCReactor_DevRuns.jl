
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# # ANALOG LEDS
# let

#     vals1, vals2 = Float64[], Float64[]

#     plot_frec = 1
#     plot_last_time = 0
#     laser_pwd = 0
#     laser_pwd1 = 30

#     while true
#         # control laser
#         # laser_pwd = mod(laser_pwd + 1, laser_pwd1)
#         # send_csvcmd(sp, "INO", "ANALOG-WRITE", 5, 0);
#         # @show laser_pwd

#         # read sensors
#         @time pkg1 = send_csvcmd(sp, "INO", "ANALOG-READ", 12)
#         isempty(pkg1["done_ack"]) && continue
#         @time pkg2 = send_csvcmd(sp, "INO", "ANALOG-READ", 8)
#         isempty(pkg2["done_ack"]) && continue
#         push!(vals1, 
#             parse(Int, pkg1["responses"][0]["data"][2])
#         )
#         push!(vals2,
#             parse(Int, pkg2["responses"][0]["data"][2])
#         )

#         # plot
#         if time() - plot_last_time > plot_frec
#             plot_last_time = time()
            
#             isempty(vals1) && continue
#             isempty(vals2) && continue

#             f = Figure()
#             limits = (nothing, nothing, -50, 1100)
#             ax = Axis(f[1, 1]; limits, ylabel = "led1")
#             scatter!(ax, eachindex(vals1), vals1; color = :blue)
#             ax = Axis(f[2, 1]; limits, xlabel = "time", ylabel = "led2")
#             scatter!(ax, eachindex(vals2), vals2; color = :red)
#             display(f)
#         end

#     end
# end