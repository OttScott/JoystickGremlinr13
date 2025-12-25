// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls


ListView {
    property bool scrollbarAlwaysVisible: false

    // Prevent content being shown outside the widget's bounds.
    clip: true

    // Scrollbar visibility behavior as configured.
    ScrollBar.vertical: ScrollBar {
        policy: scrollbarAlwaysVisible ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
    }
    // Disable mobile device scrolling behaviors.
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
}