DOWNLOADER = {}
DOWNLOADER.__index = DOWNLOADER

DOWNLOADER.Mode = {
    Disabled = 1,
    LoadingScreen = 2,
    AfterEnter = 3,
    WhenBeingUsed = 4
}

AddCSLuaFile()
AddCSLuaFile("uwdplus/cl_uwdplus_gui.lua")
AddCSLuaFile("uwdplus/cl_uwdplus.lua")
AddCSLuaFile("uwdplus/sh_uwdplus.lua")

include("uwdplus/sh_uwdplus.lua")

if CLIENT then
    include("uwdplus/cl_uwdplus_gui.lua")
    include("uwdplus/cl_uwdplus.lua")
else
    resource.AddFile("materials/uwdplus/loading.png")

    include("uwdplus/sv_uwdplus_storage.lua")
    include("uwdplus/sv_uwdplus_scanner.lua")
    include("uwdplus/sv_uwdplus.lua")

    DOWNLOADER:Start()
end