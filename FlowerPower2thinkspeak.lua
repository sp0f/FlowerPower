-- server ip address
SRV_IP='144.212.80.11' -- api.thingspeak.com
-- server port
SRV_PORT=80
-- thingspeak writekey
WRITEKEY="your thingspeak write key"
-- wifi network name
SSID="YourWiFiSSID"
-- wifi password
WIFI_PASS="WiFi Password"
-- time between measurements (in micro seconds)that ESP8266 should spend in deep sleep mode
SLEEP_TIME=60000000
-- number of readings to get from sensor
NUM_READINGS=10

GPIO12=6
GPIO13=7
GPIO14=5

gpio.mode(GPIO12,gpio.OUTPUT)
gpio.mode(GPIO13,gpio.OUTPUT)
gpio.mode(GPIO14,gpio.OUTPUT)

sum=0

function setup_wifi()
    wifi.setmode(wifi.STATION)
    wifi.sta.config(SSID,WIFI_PASS)
    wifi.sleeptype(wifi.MODEM_SLEEP)
    wifi.sta.autoconnect(1)
end

-- get sensor readings (average from 10)
function getSensorReadings()
    -- Y4 - A4 - sensor 1
    gpio.write(GPIO12,gpio.LOW)
    gpio.write(GPIO13,gpio.LOW)
    gpio.write(GPIO14,gpio.HIGH)
    sum=0    
    for i=NUM_READINGS,1,-1 do
        sum=sum+adc.read(0)        
    end
    sen1=sum/NUM_READINGS

    -- Y7 - A7 - sensor 2
    gpio.write(GPIO12,gpio.HIGH)
    gpio.write(GPIO13,gpio.HIGH)
    gpio.write(GPIO14,gpio.HIGH)
    sum=0    
    for i=NUM_READINGS,1,-1 do
        sum=sum+adc.read(0)        
    end
    sen2=sum/NUM_READINGS

    -- Y5 - A5 - sensor 3
    gpio.write(GPIO12,gpio.LOW)
    gpio.write(GPIO13,gpio.HIGH)
    gpio.write(GPIO14,gpio.HIGH)
    sum=0    
    for i=NUM_READINGS,1,-1 do
        sum=sum+adc.read(0)        
    end
    sen3=sum/NUM_READINGS
    
end

function sendData()
    getSensorReadings()
    connected=false
    
    conn=net.createConnection(net.TCP, 0)
    -- on receive print reveived data - we don't expect to run that
    conn:on("receive", function(conn, payload) 
        print("Received payload:"..payload) 
    end)
    
    -- send data when connected
    conn:on("connection", function(conn)
        connected=true
        print("Connected, sending data: "..sen1..","..sen2..","..sen3)
        
        conn:send("GET /update?api_key="..WRITEKEY.."&field1="..sen1.."&field2="..sen2.."&field3="..sen3.." HTTP/1.1\r\n") 
        conn:send("Host: api.thingspeak.com\r\n") 
        conn:send("Accept: */*\r\n") 
        conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
        conn:send("\r\n")
    end)
    -- on sent, close connection and print info about that
    conn:on("sent",function(conn)
        print("Data has been sent. Closing connection")
        conn:close()
    end)
    -- on disconnection, print info about that
    conn:on("disconnection", function(conn)
        print("Connection closed. Going into deep sleep for "..(SLEEP_TIME/1000000).."s")
        node.dsleep(SLEEP_TIME,2)
    end)
    -- connect and send
    conn:connect(SRV_PORT,SRV_IP)    
end

setup_wifi()

-- wait for IP adress and then run sendData()
tmr.alarm(1, 5000, 1, function() 
    if wifi.sta.status() ~= 5 then
      print("Waiting for IP ...") 
   else
        print("Got IP "..wifi.sta.getip())
        tmr.stop(1)
        sendData()
   end
end)


