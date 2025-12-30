// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window

import Gremlin.Device
import Gremlin.Profile
import Gremlin.Style
import Gremlin.Tools

Window {
    minimumWidth: 900
    minimumHeight: 300

    color: Style.background
    Universal.theme: Style.theme

    title: "Swap devices"

    DeviceListModel {
        id: _physicalDevices
        deviceType: "physical"
    }

    ProfileDeviceListModel {
        id: _profileDevices
    }

    Tools {
        id: _tools
    }

    property string statusMessage: "Select devices, and click the Swap Bindings button"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        // Description/Manual Section
        TextOutputBox {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            text: qsTr("<ul>" +
                    "<li>Select the devices to swap bindings between" +
                    "<li>Click 'Swap' to swap the bindings between the selected devices" +
                    "<li>Resulting bindings may be invalid if devices have different numbers " +
                    "of inputs" +
                    "</ul>")
        }

        // Main content area with device dropdowns.
        RowLayout {
            spacing: 10

            // First ("Connected") Device Column
            ColumnLayout {
                Label {
                    text: qsTr("Select connected device")
                    font.bold: true
                }

                ComboBox {
                    model: _physicalDevices
                    textRole: "name"
                    Layout.fillWidth: true
                    onActivated: _physicalDevices.selectedIndex = currentIndex
                    Component.onCompleted: _physicalDevices.selectedIndex = currentIndex
                }
            }

            // Second ("Profile") Device Column
            ColumnLayout {
                Label {
                    text: qsTr("Select device in profile")
                    font.bold: true
                }

                ComboBox {
                    model: _profileDevices
                    textRole: "uuid"
                    Layout.fillWidth: true
                    onActivated: _profileDevices.selectedIndex = currentIndex
                    Component.onCompleted: _profileDevices.selectedIndex = currentIndex

                    delegate: ItemDelegate {
                        width: parent.width
                        text: `${model.name || model.uuid}: ${model.numBindings} ${model.numBindings === 1 ? 'binding' : 'bindings'}`
                    }
                }
            }
        }

        // Action bar with button and status
        RowLayout {
            spacing: 10

            Button {
                text: qsTr("Swap Bindings")
                onClicked: {
                    statusMessage = _tools.swapDevices(
                        _profileDevices.uuidAtIndex(_profileDevices.selectedIndex),
                        _physicalDevices.uuidAtIndex(_physicalDevices.selectedIndex));
                }
            }

            TextOutputBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                text: statusMessage
            }
        }
    }
}
