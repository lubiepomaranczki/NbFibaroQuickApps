--https://forum.smartapfel.de/attachment/4358-yamaha-musiccast-http-simplified-api-for-controlsystems-pdf/

function QuickApp:Power(Event)
    local power = fibaro.getValue(self.id, "power")
    self:debug("Power is: ", fibaro.getValue(self.id, "power"))
    if power == true then
        self:sendExtended("/main/setPower?power=standby") 
        self:updateView("Power", "text", "Power On")
        self:updateProperty('power', false)
    else
        self:sendExtended("/main/setPower?power=on")
        self:updateView("Power", "text", "Power Off")
        self:updateProperty('power', true)
    end
end

function QuickApp:play()
    self:sendExtended("/netusb/setPlayback?playback=play")
end

function QuickApp:setMute(isMute)
    if(isMute==1) then
        self:debug("Mute")
        self:sendExtended("/main/setMute?enable=true")
    else
        self:debug("Unmute")
        self:sendExtended("/main/setMute?enable=false")
    end
end

function QuickApp:setVolume(volume)
    self:sendExtended("/main/setVolume?volume="..volume)
end

function QuickApp:pause()
    self:sendExtended("/netusb/setPlayback?playback=pause")
end

function QuickApp:stop()
    self:sendExtended("/netusb/setPlayback?playback=stop")
end

function QuickApp:next()
    self:sendExtended("/netusb/setPlayback?playback=next")
end

function QuickApp:prev()
    self:sendExtended("/netusb/setPlayback?playback=previous")
end

function QuickApp:sendExtended(Uri, onSuccess)
    IPAddress = self:getVariable("IPAddress")
    -- print(IPAddress)
    self.http = net.HTTPClient({
        timeout = 3000
    })
    requestUri = "http://" .. IPAddress .. "/YamahaExtendedControl/v1" .. Uri
    self:debug("YamahaExtendedControl requestUri:", requestUri)

    self.http:request(requestUri, {
        options = {
            method = "GET"
        },
        success = function(response)
            -- self:debug(response.status)
            -- self:debug(response.data)
            local data = json.decode(response.data)
            if (onSuccess ~= nil) then
                onSuccess(data)
            end
        end,
        error = function(message)
            self:debug("error:", message)
        end
    })

end

--Taken from:
--Quick App created by Andrzej Socha
--licensed on GPL
--Based on: https://marketplace.fibaro.com/items/musiccast-for-hc3
function QuickApp:Info()
    local url = "http://" .. self:getVariable("IPAddress")
    local queryinfo = "/YamahaExtendedControl/v1/netusb/getPlayInfo"

    local urlinfo = url .. "" .. queryinfo

    self.http:request(urlinfo, {
        options = {
            headers = {
                Accept = "application/json"
            },
            checkCertificate = true,
            method = 'GET'
        },
        success = function(response)
            -- self:debug("response status:", response.status) 
            -- self:debug("headers:", response.headers["Content-Type"]) 
            local info = json.decode(response.data)

            input = (info.input)
            status = (info.playback)
            artist = (info.artist)
            album = (info.album)
            track = (info.track)
            albumurl = (info.albumart_url)
            -- self:debug("Input: "..input.." | Artist: "..artist.." | Album: "..album.." | Track: "..track) 
            self:updateView("input", "text", "Source: " .. input .. " | Status: " .. status)
            self:updateView("artist", "text", "Artist: " .. artist)
            self:updateView("album", "text", "Album: " .. album)
            self:updateView("track", "text", "Track: " .. track)
        end,
        error = function(error)
            self:debug('error: ' .. json.encode(error))
        end
    })
    fibaro.setTimeout(2000, function()
        self:Info()
    end)
end

function QuickApp:onInit()
    ID = tonumber(self:getVariable("ID"))
    vSlider = fibaro.getValue(tonumber(ID), "volume")

    self:sendExtended("/main/getStatus", function(response)
        self:debug(response.power)
        if (response.power == "on") then
            self:updateView("Power", "text", "Power OFF")
            self:updateProperty("power", true)

        else
            self:updateView("Power", "text", "Power ON")
            self:updateProperty("power", false)
        end
    end)
    self:Info()  
end
