-- Shows system information --

return {

    name = "aptfetch",
    description = "Displays system information like the cool arch users do.",
    required_permission = "basic",
    required_group = "guest",
    help = "Displays system information. Just run it.",

    execute = function(...)

        print ("-- PLACEHOLDER OS -- ")

        print ("MMMMMMMMMMMMMMMMWKOOOO0NWMMMMMMMMMMMMMMM")
        print ("MMMMMMMMMMMMWXkl,......':xNMMMMMMMMMMMMM")
        print ("MMMMMMMMMMMNd'..':clll:,..'l0WMMMMMMMMMM")
        print ("MMMMMMMMMNO:..;oxxxxxdxxoc,..c0WMMMMMMMM")
        print ("MMMMMMMMKl..;oxxxdoooooxxxxo' 'kWMMMMMMM")
        print ("MMMMMMM0; .cxxxl;......':dxxo, .xNMMMMMM")
        print ("MMMMMMNc .ldxo:..,coxdl,..lxkd, .xWMMMMM")
        print ("MMMMMWx..cxxo'.,xNMMMMMXc.'dkkd, 'OWMMMM")
        print ("MMMMM0,.;dxd:.;KMMMMMMMM0,.lkkOo..dWMMMM")
        print ("MMMMXc 'oxdd:.:NMMMMMMMMX;.lOkOk;.:XMMMM")
        print ("MMMMk..cdxxxc..:llllllllc..oOOOOo.'OMMMM")
        print ("MMMMk.'oxxxxxl:;;;::;;::::okOOOOd''OMMMM")
        print ("MMMMx.'oxxxxxxxkkkkkkkkOOOOOOOOOd''OMMMM") 
        print ("MMMX:.;dxxxxxkkkxdollloxOOOOOOOOd''OMMMM")
        print ("MMMK,.cxxxxkkkxo,..,;..;dOOOOkkko.'OMMMM")
        print ("MMMX:.;dxxkkkx:..l0NN0:.'dOkkkkx:.;KMMMM")
        print ("MMMMk.'dkkkkx,.lNMMMMMWk..okkkkc.'OMMMMM")
        print ("MMMMk..:xxkkx'.kMMMMMMM0'.oxdol, cNMMMMM")
        print ("MMMMK;..,'',,..OMMMMMMM0' .''...;0MMMMMM")
        print ("-------------PLACEHOLDER OS-------------")

        os.sleep(1.5)


        local uptimeRaw = math.floor(os.clock())
        local uptime = 0
        local timeUnit = "nothing"

        if uptimeRaw < 60 then
            timeUnit = "seconds"
            uptime = uptimeRaw
        elseif uptimeRaw > 60 and uptimeRaw < 3600 then
            timeUnit = "minutes"
            uptime = math.floor(uptimeRaw / 60)
        elseif uptimeRaw < 3600 then
            timeUnit = "hours"
            uptime = math.floor(uptimeRaw/3600)
        end

        print("Operating System:", _G.metadata.name) 
        print("Kernel:", _G.metadata.kernel)
        print("Version:", _G.metadata.version)
        print("Uptime:", uptime, timeUnit)

    end
}