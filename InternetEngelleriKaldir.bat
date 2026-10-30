@echo off
:: Engelleri Kaldır - Okul Interneti
:: Yönetici olarak çalıştırılmalı

echo ========================================
echo    Okul Interneti Engelleri Kaldırılıyor
echo ========================================
echo.

:: Proxy ayarlarını sıfırla (proxy sunucusunu temizle)
echo [1/4] Proxy ayarları sıfırlanıyor...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^
    /v ProxyServer /t REG_SZ /d "" /f ^
    /v ProxyEnable /t REG_DWORD /d 0 /f ^
    /v ProxyOverride /t REG_SZ /d "" /f

:: Hosts dosyasına gerekli satırları ekle (isteğe bağlı: engelleyen siteleri çıkar)
echo [2/4] Hosts dosyası kontrol ediliyor...
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
if exist "%HOSTS%" (
    echo - Hosts dosyası bulundu.
    :: Mevcut engelleri sil (örneğin: facebook.com, youtube.com, vs.)
    for %%s in (facebook.com youtube.com instagram.com twitter.com tiktok.com) do (
        findstr /v "^[^#].*%%s" "%HOSTS%" > "%HOSTS%.new"
        move /y "%HOSTS%.new" "%HOSTS%" >nul
    )
    echo - Engellenen siteler hosts dosyasından çıkarıldı.
)

:: Güvenlik duvarı kurallarını sıfırla (özellikle giden trafiğe engel koyan kuralları)
echo [3/4] Güvenlik Duvarı kuralları güncelleniyor...
netsh advfirewall reset
:: Giden tüm trafiğe izin ver (varsayılan ayarlarla)
netsh advfirewall set allprofiles state on
netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound

:: DNS önbelleğini temizle
echo [4/4] DNS önbelleği temizleniyor...
ipconfig /flushdns

echo.
echo ========================================
echo    TAMAMLANDI - Engeller kaldırıldı!
echo ========================================
echo.
echo Not: Değişikliklerin geçerli olması için tarayıcıyı yeniden açmanız önerilir.
echo.
pause
