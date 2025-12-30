// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs

import Gremlin.Profile
import Gremlin.ActionPlugins
import "../../qml"

Item {
    property LoadProfileModel action

    implicitHeight: _content.height

    RowLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            Layout.preferredWidth: 150

            text: "Profile filename"
        }

        JGTextField {
            id: _profileFilename

            Layout.fillWidth: true

            placeholderText: null !== action ? null : "Enter a profile filename"
            text: action.profile_filename
            selectByMouse: true

            onTextChanged: () => { action.profile_filename = text }
        }

        Button {
            text: "Select File"
            onClicked: () => { _fileDialog.open() }
        }
   }

   FileDialog {
        id: _fileDialog
        nameFilters: ["Profile files (*.xml)"]
        title: "Select a File"
        onAccepted: () =>{
            _profileFilename.text = selectedFile.toString().substring("file:///".length)
        }
    }
}
