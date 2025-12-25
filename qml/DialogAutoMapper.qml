// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Device
import Gremlin.Profile
import Gremlin.Tools


Window {
    minimumWidth: 900
    minimumHeight: 400

    title: "Auto Mapper: Maps your physical controls to vJoy inputs"

    DeviceListModel {
        id: physicalDevices
        deviceType: "physical"
    }

    DeviceListModel {
        id: virtualDevices
        deviceType: "virtual"
    }

    Tools {
        id: tools
    }

    // Properties to track the selected devices and user selections.
    property string selectedMode: ""
    property var selectedPhysicalDevices: ({})
    property var selectedVJoyDevices: ({})
    property bool overwriteNonEmpty: false
    property bool repeatVJoy: false

    property string statusMessage: "Select devices, options and click the Create button"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Description/Manual Section
        TextOutputBox {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            text: qsTr("<ul>" +
                    "<li>Select mode to create bindings in" +
                    "<li>Select source physical devices and target vJoy devices" +
                    "<li>Click 'Create 1:1 mappings' to map from physical to virtual inputs" +
                    "<li>Enable 'Overwrite non-empty' to replace existing mappings in the profile" +
                    "<li>Enable 'Repeat vJoy' to cycle through vJoy inputs, if needed to map all physical inputs" +
                    "</ul>")
        }

        // Mode selection.
        RowLayout {
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
            }

            TextOutputBox {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 30
                border.color: Universal.background
                text: "Select Mode"
            }

            ComboBox {
                model: backend.modeHierarchy.modeList
                textRole: "name"
                onActivated: selectedMode = currentText
                Component.onCompleted: selectedMode = currentText
            }
        }

        // Main content area with device lists
        RowLayout {
            spacing: 10

            // Physical Devices Column
            ColumnLayout {
                spacing: 5

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: qsTr("Physical Devices")

                    JGListView {
                        anchors.fill: parent
                        model: physicalDevices
                        delegate: CheckBox {
                            width: ListView.view.width - 10
                            text: model.name
                            checked: false
                            onCheckedChanged: {
                                selectedPhysicalDevices[model.guid] = checked;
                            }
                        }
                    }
                }

                Switch {
                    id: _overwriteSwitch
                    text: qsTr("Overwrite non-empty physical inputs")

                    ToolTip {
                        visible: parent.hovered
                        text: qsTr("Overwrite non-empty physical inputs")
                        delay: 500
                    }

                    onToggled: function() {
                        overwriteNonEmpty = checked;
                    }
                }
            }

            // vJoy Devices Column
            ColumnLayout {
                spacing: 5

                GroupBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    title: qsTr("vJoy Devices")

                    JGListView {
                        anchors.fill: parent
                        model: virtualDevices
                        delegate: CheckBox {
                            width: ListView.view.width - 10
                            text: model.name + model.vjoy_id
                            checked: false
                            onCheckedChanged: {
                                selectedVJoyDevices[model.vjoy_id] = checked;
                            }
                        }
                    }
                }

                Switch {
                    id: _repeatSwitch
                    text: qsTr("Repeat vJoy devices")

                    ToolTip {
                        visible: parent.hovered
                        text: qsTr("Repeat vJoy devices")
                        delay: 500
                    }

                    onToggled: function() {
                        repeatVJoy = checked;
                    }
                }
            }
        }

        // Action bar with button and status
        RowLayout {
            Layout.preferredHeight: 35
            spacing: 10

            Button {
                id: _createButton
                text: qsTr("Create 1:1 mappings")
                Layout.preferredWidth: implicitWidth + 20
                Layout.preferredHeight: 30
                onClicked: {
                    statusMessage = tools.createMappings(
                        selectedMode,
                        selectedPhysicalDevices, selectedVJoyDevices,
                        overwriteNonEmpty, repeatVJoy);
                }
            }

            TextOutputBox {
                id: _statusNotification
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                text: statusMessage
            }
        }
    }
}
