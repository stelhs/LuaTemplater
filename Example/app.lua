require 'LuaTemplater'

function _printToFile(fileName, content)
    local file = io.open(fileName, 'w')

    file:write(content)

    file:close()
end

function main ()
    local ltpl = LTpl.new 'Templates/main.html'

    ltpl:assign('basicSettings', {
        enableWirelessChecked = 'checked';
        broadcastWirelessNetwordChecked = 'checked';
        MBSSID = 'Disabled';
        BSSID = 'C4:A8:1D:DB:1F:EC';
        SSID = 'ROOM_701A';
        maxClients = 0;
    })

    ltpl:assign('countryBlock', {
        checked1 = 'selected'
    })

    ltpl:assign('channelBlock', {
        checked1 = 'selected'
    })

    ltpl:assign('wirelessModeBlock', {
        checked3 = 'selected'
    })

    ltpl:assign('securitySettings', {
        encriptionKey = 'password';
        wpaRenewal = '3600';
    })

    ltpl:assign('networkAuthBlock', {
        selected3 = 'selected';
    })


    ltpl:assign('listOfClients', {})

    ltpl:assign('client', {
        mac = 'D0:51:62:6C:EC:B0';
        band = '2.4 GHz';
        online = '619';
        tx = '116057';
        rx = '51414';
        rssi = '65';
    })

    ltpl:assign('client', {
        mac = 'D7:94:F7:24:9A:DB';
        band = '2.4 GHz';
        online = '5';
        tx = '43245';
        rx = '4254';
        rssi = '45';
    })

    ltpl:assign('client', {
        mac = '70:B4:83:73:5D:51';
        band = '2.4 GHz';
        online = '4566';
        tx = '345343';
        rx = '353453';
        rssi = '48';
    })

    _printToFile('Rendered/main.html', ltpl:getContent())
end

main ()