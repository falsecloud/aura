#!/usr/bin/env python3
"""Aura - native Qt Quick desktop app."""

from __future__ import annotations

import argparse
import ctypes
import os
import sys

from PySide6.QtCore import QTimer, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from backend import BASE, Backend


def _has_vulkan_device() -> bool:
    """Check for a usable Vulkan GPU before Qt tries to initialize Vulkan."""

    class VkApplicationInfo(ctypes.Structure):
        _fields_ = [
            ("sType", ctypes.c_int),
            ("pNext", ctypes.c_void_p),
            ("pApplicationName", ctypes.c_char_p),
            ("applicationVersion", ctypes.c_uint32),
            ("pEngineName", ctypes.c_char_p),
            ("engineVersion", ctypes.c_uint32),
            ("apiVersion", ctypes.c_uint32),
        ]

    class VkInstanceCreateInfo(ctypes.Structure):
        _fields_ = [
            ("sType", ctypes.c_int),
            ("pNext", ctypes.c_void_p),
            ("flags", ctypes.c_uint32),
            ("pApplicationInfo", ctypes.POINTER(VkApplicationInfo)),
            ("enabledLayerCount", ctypes.c_uint32),
            ("ppEnabledLayerNames", ctypes.c_void_p),
            ("enabledExtensionCount", ctypes.c_uint32),
            ("ppEnabledExtensionNames", ctypes.c_void_p),
        ]

    try:
        loader = ctypes.CDLL("libvulkan.so.1")
        create_instance = loader.vkCreateInstance
        create_instance.argtypes = [
            ctypes.POINTER(VkInstanceCreateInfo),
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_void_p),
        ]
        create_instance.restype = ctypes.c_int
        enumerate_devices = loader.vkEnumeratePhysicalDevices
        enumerate_devices.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint32),
            ctypes.c_void_p,
        ]
        enumerate_devices.restype = ctypes.c_int
        destroy_instance = loader.vkDestroyInstance
        destroy_instance.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    except (OSError, AttributeError):
        return False

    application_info = VkApplicationInfo(
        sType=0,
        pNext=None,
        pApplicationName=b"Aura",
        applicationVersion=1,
        pEngineName=b"Aura",
        engineVersion=1,
        apiVersion=1 << 22,
    )
    create_info = VkInstanceCreateInfo(
        sType=1,
        pNext=None,
        flags=0,
        pApplicationInfo=ctypes.pointer(application_info),
        enabledLayerCount=0,
        ppEnabledLayerNames=None,
        enabledExtensionCount=0,
        ppEnabledExtensionNames=None,
    )
    instance = ctypes.c_void_p()
    try:
        if create_instance(ctypes.byref(create_info), None, ctypes.byref(instance)) != 0:
            return False
        try:
            count = ctypes.c_uint32()
            if enumerate_devices(instance, ctypes.byref(count), None) != 0:
                return False
            return count.value > 0
        finally:
            destroy_instance(instance, None)
    except Exception:
        return False


# Liquid glass is a real refraction shader, so prefer Vulkan. VMs and machines
# without a Vulkan GPU would abort inside Qt if Vulkan were forced, so fall back
# to OpenGL when no physical Vulkan device is present.
if "QSG_RHI_BACKEND" not in os.environ:
    if _has_vulkan_device():
        os.environ["QSG_RHI_BACKEND"] = "vulkan"
    else:
        os.environ["QSG_RHI_BACKEND"] = "opengl"
        print("Aura: no Vulkan GPU detected; using the OpenGL backend.", file=sys.stderr)


# PyInstaller puts bundled QML modules under the frozen _internal directory.
def _configure_bundled_qml_path() -> None:
    qml_dir = os.path.join(BASE, "PySide6", "Qt", "qml")
    if not os.path.isdir(qml_dir):
        return
    existing = os.environ.get("QML_IMPORT_PATH", "")
    entries = existing.split(os.pathsep) if existing else []
    if qml_dir not in entries:
        os.environ["QML_IMPORT_PATH"] = os.pathsep.join([qml_dir, *entries])


_configure_bundled_qml_path()


def main() -> int:
    parser = argparse.ArgumentParser(description="Aura")
    parser.add_argument("--shot", help="Save a screenshot to this path and quit")
    parser.add_argument("--delay", type=int, default=6500, help="Screenshot delay in ms")
    parser.add_argument("--page", type=int, default=0, help="Initial page index")
    parser.add_argument("--search", action="store_true", help="Open the search overlay")
    args = parser.parse_args()

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Aura")
    app.setApplicationDisplayName("Aura")
    app.setOrganizationName("Aura")
    app.setDesktopFileName("aura")
    icon_path = os.path.join(BASE, "assets", "app.png")
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))

    engine = QQmlApplicationEngine()
    engine.warnings.connect(
        lambda warnings: [print(w.toString(), file=sys.stderr) for w in warnings]
    )
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(os.path.join(BASE, "qml", "Main.qml")))
    if not engine.rootObjects():
        return 1

    window = engine.rootObjects()[0]
    backend.bootstrap()

    window.setProperty("page", args.page)
    if args.search:
        window.setProperty("searchOpen", True)
    if args.shot:
        window.setProperty("shotPath", args.shot)

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
