# -*- mode: python ; coding: utf-8 -*-

import os

import PySide6
from PySide6.QtCore import QLibraryInfo

root = os.path.abspath(os.path.join(SPECPATH, ".."))

# Only bundle the QML modules imported by Aura (and their runtime deps).
# Collecting all Qt QML on distro installs drags in unrelated KDE/Plasma
# modules and multiplies the package size.
try:
    qml_root = QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath)
except AttributeError:
    qml_root = QLibraryInfo.path(QLibraryInfo.QmlImportsPath)
if not qml_root or not os.path.isdir(qml_root):
    qml_root = os.path.join(
        os.path.dirname(os.path.abspath(PySide6.__file__)), "Qt", "qml"
    )

datas = [
    (os.path.join(root, "qml"), "qml"),
    (os.path.join(root, "assets"), "assets"),
    (os.path.join(root, "media"), "media"),
]
for module in ("QtQml", "QtQuick", "QtMultimedia"):
    source = os.path.join(qml_root, module)
    if os.path.isdir(source):
        datas.append((source, os.path.join("PySide6", "Qt", "qml", module)))

hiddenimports = [
    "PySide6.QtMultimedia",
    "PySide6.QtNetwork",
    "PySide6.QtQml",
    "PySide6.QtQuick",
]

a = Analysis(
    [os.path.join(root, "main.py")],
    pathex=[root],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[os.path.join(root, "packaging", "hooks")],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="Aura",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=os.path.join(root, "assets", "app.png"),
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name="Aura",
)
