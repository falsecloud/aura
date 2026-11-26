# AUR package

`aura-weather` is the source-based Arch package. It installs the application
into `/opt/aura-weather` and uses Arch's `pyside6`/Qt 6 packages instead of the
self-contained PyInstaller bundle used by the release pacman package.

Build it locally:

```bash
makepkg -f
sudo pacman -U aura-weather-*.pkg.tar.zst
```

To submit it to the AUR, an AUR account and an SSH key registered with that
account are required:

```bash
git clone ssh://aur@aur.archlinux.org/aura-weather.git
cp PKGBUILD .SRCINFO aura-weather/
cd aura-weather
git add PKGBUILD .SRCINFO
git commit -m "Initial import: aura-weather 1.0.1"
git push
```
