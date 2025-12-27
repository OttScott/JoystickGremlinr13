// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtCharts

import QtQuick.Controls.Universal

import Gremlin.Device


Item {
    id: _root

    property string deviceGuid
    property string title
    property var colors: [
        "#1f77b4",
        "#d62728",
        "#2ca02c",
        "#ff7f0e",
        "#7f7f7f",
        "#bcbd22",
        "#17becf",
        "#9467bd",
    ]

    function compute_height(available_width)
    {
        return _chart.height + _header.height
    }

    DeviceAxisSeries {
        id: _axis_series

        guid: deviceGuid

        onDeviceChanged: function() {
            _chart.removeAllSeries()

            for(var i=0; i<axisCount; i++)
            {
                var series = _chart.createSeries(
                    ChartView.SeriesTypeLine,
                    "Axis " + axisIdentifier(i),
                    _x_axis,
                    _y_axis
                )
               series.color = colors[i]
            }
        }
    }

    Timer {
        interval: 10
        running: true
        repeat: true
        onTriggered: function()
        {
            for(var i=0; i<_chart.count; i++)
            {
                _axis_series.updateSeries(_chart.series(i), i)
            }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            id: _header

            JGText {
                text: title + " - Axes"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                height: 2
                color: Universal.baseLowColor
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 300

            z: -1
            clip: true

            ChartView {
                id: _chart

                margins {
                    top: 0
                    bottom: 0
                    left: 0
                    right: 0
                }

                y: -20
                width: parent.width
                height: parent.height

                antialiasing: true

                ValueAxis {
                    id: _y_axis

                    min: -1
                    max: 1
                }

                ValueAxis {
                    id: _x_axis

                    min: -_axis_series.windowSize
                    max: 0
                }
            }
        }
    }

}