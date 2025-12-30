// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

pragma Singleton

import QtQuick
import QtQuick.Controls.Universal

Item {
    property bool isDarkMode: false

    property var accent: Universal.accent
    property var theme: isDarkMode ? Universal.Dark : Universal.Light
    property var background: isDarkMode ? Universal.foreground : Universal.background
    property var foreground: isDarkMode ? Universal.background : Universal.foreground
    property var backgroundShade: isDarkMode ? Qt.tint(background, "#40ffffff") : Qt.tint(foreground, "#b0ffffff")
    property var lowColor: isDarkMode ? Qt.darker(foreground, 1.5) : Universal.baseLowColor
    property var error: "crimson"
}