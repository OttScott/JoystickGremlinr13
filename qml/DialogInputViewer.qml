// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window

import Gremlin.Device
import Gremlin.Style

Window {
    minimumWidth: 900
    minimumHeight: 500

    color: Style.background
    Universal.theme: Style.theme

    title: "Input Viewer"

    DeviceListModel {
        id: _deviceData

        deviceType: "all"
    }

    function recompute_height()
    {
        for(let i=0; i<_stateDisplay.children.length; ++i)
        {
            let elem = _stateDisplay.children[i]
            elem.implicitHeight = elem.compute_height(_stateDisplay.width)
        }
    }

    function create_widget(qml_path, guid, name)
    {
        let component = Qt.createComponent(Qt.resolvedUrl(qml_path))
        let widget = component.createObject(
            _stateDisplay,
            {
                deviceGuid: guid,
                title: name
            }
        )

        widget.Layout.fillWidth = true
        recompute_height()
        return widget
    }

    RowLayout {
        id: _root

        anchors.fill: parent

        ScrollView {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: 250
            Layout.fillWidth: false
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent

                Repeater {
                    model: _deviceData
                    delegate: _deviceDelegate
                }
            }
        }

        // Dynamic scrollview that contains dynamically generated widgets
        ScrollView  {
            id: _dynamic_scroll

            Layout.fillWidth: true
            Layout.fillHeight: true

            Component.onCompleted: {
                _dynamic_scroll.contentItem.boundsMovement = Flickable.StopAtBounds
                _dynamic_scroll.contentItem.boundsBehavior = Flickable.StopAtBounds
            }

            ColumnLayout {
                id: _stateDisplay

                anchors.left: parent.left
                anchors.right: parent.right

                onWidthChanged: function() {
                    recompute_height()
                }
            }
        }
    }

    // Display the collapsible visualization toggles for a single device
    Component {
        id: _deviceDelegate

        ColumnLayout {
            id: _delegateContent

            required property int index
            required property string name
            required property string guid

            // Variable holding references to the widgets visualizing device
            // input states
            property var widget_btn_hat
            property var widget_axis_temp
            property var widget_axis_cur

            // Device header
            RowLayout {
                IconButton {
                    id: _foldButton

                    checkable: true
                    checked: false
                    text: checked ? bsi.icons.folded : bsi.icons.unfolded
                }

                JGText {
                    text: name
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    height: 2
                    color: Style.lowColor
                }
            }

            // Per device visualization toggles
            ColumnLayout {
                visible: _foldButton.checked

                Layout.leftMargin: _foldButton.width

                Switch {
                    text: "Axes - Temporal"

                    onClicked: function()
                    {
                        if(checked)
                        {
                            widget_axis_temp = create_widget(
                                "AxesStateSeries.qml",
                                guid,
                                name
                            )
                        }
                        else
                        {
                            widget_axis_temp.destroy()
                        }
                    }
                }
                Switch {
                    text: "Axes - Current"

                    onClicked: function()
                    {
                        if(checked)
                        {
                            widget_axis_cur = create_widget(
                                "AxesStateCurrent.qml",
                                guid,
                                name
                            )
                        }
                        else
                        {
                            widget_axis_cur.destroy()
                        }
                    }
                }
                Switch {
                    text: "Buttons & Hats"

                    onClicked: function()
                    {
                        if(checked)
                        {
                            widget_btn_hat = create_widget(
                                "ButtonState.qml",
                                guid,
                                name
                            )
                        }
                        else
                        {
                            widget_btn_hat.destroy()
                        }
                    }
                }
            }
        }
    }
}
