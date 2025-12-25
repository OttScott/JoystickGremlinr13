// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Config
import "helpers.js" as Helpers


Window {
    minimumWidth: 800
    minimumHeight: 600

    title: "Options"

    ConfigSectionModel {
        id: _sectionModel
    }

    RowLayout {
        id: _root

        anchors.fill: parent

        // Shows the list of all option sections
        JGListView {
            id: _sectionSelector

            Layout.preferredWidth: 200
            Layout.fillHeight: true

            model: _sectionModel
            delegate: ConfigSectionButton {}

            Component.onCompleted: () => {
                itemAtIndex(0).toggle()
            }
        }

        // Shows the contents of the currently selected section
        ConfigSection {
            id: _configSection

            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }
}