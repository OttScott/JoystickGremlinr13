// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick


Item {
    property alias icons: _icon_names
    property alias resource: _loader.resource

    readonly property string family: "bootstrap-icons"

    FontLoader {
        id: _loader

        property string resource

        source: resource
    }

    BootstrapIconsNames {
        id: _icon_names
    }
}