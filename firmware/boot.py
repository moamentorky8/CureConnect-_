import network
import time
import machine

# إعدادات شبكة الواي فاي الخاصة بك
# ملاحظة: يمكنك تغييرها لاحقاً أو جعل الجهاز يبحث عن الشبكات المتاحة
WIFI_SSID = "Your_WiFi_Name"
WIFI_PASS = "Your_WiFi_Password"

def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    
    if not wlan.isconnected():
        print('Connecting to WiFi...', WIFI_SSID)
        wlan.connect(WIFI_SSID, WIFI_PASS)
        
        # محاولة الاتصال لمدة 10 ثواني كحد أقصى
        attempt = 0
        while not wlan.isconnected() and attempt < 10:
            time.sleep(1)
            attempt += 1
            print('.', end='')
            
    if wlan.isconnected():
        print('\nWiFi Connected!')
        print('Network Config:', wlan.ifconfig())
    else:
        print('\nWiFi Connection Failed! Running in Offline Mode.')

# تشغيل دالة الاتصال عند الإقلاع
connect_wifi()

# تفعيل الـ Garbage Collector لتحسين استهلاك الرام
import gc
gc.collect()
