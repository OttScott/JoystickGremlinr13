// -*- coding: utf-8; -*-
//
// Copyright (C) 2015 - 2020 Lionel Ott
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Dialogs 1.3
import QtQuick.Window 2.14

import gremlin.ui.device 1.0

import "helpers.js" as Helpers


ApplicationWindow {

    // Basic application setup
    title: backend.windowTitle
    width: 1000
    height: 680
    visible: true
    id: root

    MessageDialog {
        id: idErrorDialog
        title: "An error occurred"
        standardButtons: StandardButton.Ok

        text: backend.lastError

        onTextChanged: {
            visible = true
        }
    }

    FileDialog {
        id: idSaveProfileFileDialog
        title: "Please choose a file"
        folder: shortcuts.home
        defaultSuffix: "xml"
        nameFilters: ["Profile files (*.xml)"]
        selectExisting: false

        onAccepted: {
            backend.saveProfile(Helpers.pythonizePath(fileUrl))
        }
    }

    FileDialog {
        id: idLoadProfileFileDialog
        title: "Please choose a file"
        folder: shortcuts.home
        defaultSuffix: "xml"
        nameFilters: ["Profile files (*.xml)"]
        selectExisting: true

        onAccepted: {
            backend.loadProfile(Helpers.pythonizePath(fileUrl))
        }
    }

    // Menu bar with all its entries
    menuBar: MenuBar {
        Menu {
            title: qsTr("File")

            MenuItem {
                text: qsTr("New Profile")
                onTriggered: {
                    backend.newProfile()
                }
            }
            MenuItem {
                text: qsTr("Load Profile")
                onTriggered: {
                    idLoadProfileFileDialog.open()
                }
            }

            AutoSizingMenu {
                title: qsTr("Recent")

                Repeater {
                    model: backend.recentProfiles
                    delegate: MenuItem {
                        text: modelData
                        onTriggered: {
                            backend.loadProfile(modelData)
                        }
                    }
                }
            }

            MenuItem {
                text: qsTr("Save Profile")
                onTriggered: {
                    var fpath = backend.profilePath()
                    if(fpath == "")
                    {
                        idSaveProfileFileDialog.open();
                    }
                    else
                    {
                        backend.saveProfile(fpath)
                    }
                }
            }
            MenuItem {
                text: qsTr("Save Profile As")
                onTriggered: {
                    idSaveProfileFileDialog.open()
                }
            }
            MenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit();
            }
        }
        Menu {
            title: qsTr("Tools")

            MenuItem {
                text: qsTr("Manage Modes")
                onTriggered: Helpers.createComponent("DialogManageModes.qml")
            }
            MenuItem {
                text: qsTr("Input Repeater")
                //onTriggered: Helpers.createComponent(".qml")
            }
            MenuItem {
                text: qsTr("Device Information")
                onTriggered: Helpers.createComponent("DialogDeviceInformation.qml")
            }
            MenuItem {
                text: qsTr("Calibration")
                onTriggered: Helpers.createComponent("DialogCalibration.qml")
            }
            MenuItem {
                text: qsTr("Input Viewer")
                onTriggered: Helpers.createComponent("DialogInputViewer.qml")
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("PDF Cheatsheet")
                onTriggered: Helpers.createComponent("DialogPDFCheatsheet.qml")
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Options")
                onTriggered: Helpers.createComponent("DialogOptions.qml")
            }
            MenuItem {
                text: qsTr("Log Display")
                onTriggered: Helpers.createComponent("DialogLogDisplay.qml")
            }
        }

        Menu {
            title: qsTr("Help")

            MenuItem {
                text: qsTr("About")
                onTriggered: Helpers.createComponent("DialogAbout.qml")
            }
        }
    }


    DeviceListModel {
        id: idDeviceListModel
    }

    Device {
        id: idDeviceModel
    }


    // Trigger an update of the input list when the model's content changes
    Connections {
        target: backend
        onInputConfigurationChanged: {
            idDeviceModel.modelReset()
        }
    }
    Connections {
        target: backend
        onReloadUi: {
            idDeviceModel.modelReset()
            idDeviceListModel.modelReset()
            idInputConfigurationPanel.reload()
        }
    }

    // List of all detected devices
    DeviceList {
        id: idDevicePanel

        height: 50
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        deviceListModel: idDeviceListModel

        // Trigger a model update on the DeviceInputList
        onDeviceGuidChanged: {
            idDeviceModel.guid = deviceGuid
        }
    }

    // Device inputs and configuration of a specific input
    SplitView {
        id: idContentLayout

        anchors.top: idDevicePanel.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        orientation: Qt.Horizontal

        // List all inputs of a single device
        DeviceInputList {
            id: idDeviceInputList
            device: idDeviceModel
            SplitView.minimumWidth: 200

            // Trigger a model update on the InputConfiguration
            onInputIdentifierChanged: {
                idInputConfigurationPanel.actionConfigurationListModel =
                    backend.getInputItem(inputIdentifier).actionConfigurations
                idInputConfigurationPanel.inputIdentifier = inputIdentifier
            }

            // Ensure initial state of input list and input configuration is
            // synchronized
            Component.onCompleted: {
                inputIdentifier = device.inputIdentifier(inputIndex)
            }
        }

        // Configuration of the selected input
        InputConfiguration {
            id: idInputConfigurationPanel
        }
    }

} // ApplicationWindow
