%{!?version:%global version 1.0.0}

Name:           aura-weather
Version:        %{version}
Release:        1%{?dist}
Summary:        Liquid-glass weather for your desktop
License:        MIT
URL:            https://github.com/falsecloud/aura
Source0:        Aura-%{version}-x86_64.tar.gz
BuildArch:      x86_64
AutoReqProv:    no
%global debug_package %{nil}

%description
Aura is a native Qt Quick weather app with real shader-based glass,
animated condition backdrops, hourly and 10-day forecasts, and saved
places. Forecast data comes from Open-Meteo and requires no API key.

%prep
%setup -q -n Aura

%install
rm -rf %{buildroot}
install -d %{buildroot}/opt/aura-weather
cp -a . %{buildroot}/opt/aura-weather/
rm -rf %{buildroot}/opt/aura-weather/aura-launcher
rm -rf %{buildroot}/opt/aura-weather/aura.desktop
rm -rf %{buildroot}/opt/aura-weather/icons
rm -rf %{buildroot}/opt/aura-weather/LICENSE

install -Dm755 aura-launcher %{buildroot}/usr/bin/aura
install -Dm644 aura.desktop %{buildroot}/usr/share/applications/aura.desktop
for size in 16 24 32 48 64 128 256 512; do
    install -Dm644 "icons/${size}.png" \
        "%{buildroot}/usr/share/icons/hicolor/${size}x${size}/apps/aura.png"
done
install -Dm644 LICENSE %{buildroot}/usr/share/licenses/aura-weather/LICENSE

%files
/opt/aura-weather
/usr/bin/aura
/usr/share/applications/aura.desktop
/usr/share/icons/hicolor/*/apps/aura.png
/usr/share/licenses/aura-weather/LICENSE

%changelog
* Wed Nov 26 2026 falsecloud <319977598+falsecloud@users.noreply.github.com> - 1.0.0-1
- Initial release of Aura.
