// -*- coding: utf-8; -*-
//
// Copyright (C) 2015 - 2025 Lionel Ott
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


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal
import QtQuick.Shapes
import Qt.labs.qmlmodels

import QtCharts

import Gremlin.Profile
import Gremlin.ActionPlugins
import "../../qml"

import "render_helpers.js" as RH


Item {
    id: _root

    property ResponseCurveModel action
    property Deadzone deadzone: action.deadzone
    property alias widgetSize : _vis.size
    property int currentIndex : 0
    readonly property int handleOffset: 5

    implicitHeight: _content.height

    // Handle model value changes as propert bindings run into cyclical
    // trigger challenges
    Component.onCompleted: function() {
        setLow(deadzone.low)
        setCenterLow(deadzone.centerLow)
        setCenterHigh(deadzone.centerHigh)
        setHigh(deadzone.high)
    }

    Connections {
        target: deadzone

        function onLowModified(value) { setLow(value) }
        function onCenterLowModified(value) { setCenterLow(value) }
        function onCenterHighModified(value) { setCenterHigh(value) }
        function onHighModified(value) { setHigh(value) }
    }

    function setLow(value) {
        _spinLow.realValue = value
        _sliderLow.first.value = value
    }

    function setCenterLow(value) {
        _spinCenterLow.realValue = value
        _sliderLow.second.value = value
    }

    function setCenterHigh(value) {
        _spinCenterHigh.realValue = value
        _sliderHigh.first.value = value
    }

    function setHigh(value) {
        _spinHigh.realValue = value
        _sliderHigh.second.value = value
    }

    function map2u(x) {
        return RH.x2u(x, _curve.x, _vis.size, handleOffset)
    }

    function map2v(y) {
        return RH.y2v(y, _curve.x, _vis.size, handleOffset)
    }

    function map2x(u, du) {
        return RH.u2x(
            du === null ? u : u + du - handleOffset,
            handleOffset,
            _vis.size
        )
    }
    function map2y(v, dv) {
        return RH.v2y(
            dv === null ? v : v + dv - handleOffset,
            handleOffset,
            _vis.size
        )
    }

    function updateControlPoint(cp_handle, evt, index) {
        let new_x = RH.clamp(map2x(cp_handle.x, evt.x), -1.0, 1.0)
        let new_y = RH.clamp(map2y(cp_handle.y, evt.y ), -1.0, 1.0)

        // Ensure the points at either end cannot be moved away from the edge
        if (index === 0) {
            new_x = -1.0
        }
        if (index === action.controlPoints.length - 1) {
            new_x = 1.0
        }

        // In symmetry mode moving the center point, if there is one is
        // not allowed
        if (_root.action.isSymmetric && _repeater.count % 2 !== 0 &&
            index * 2 + 1 === _repeater.count)
        {
            return null
        }

        // Prevent moving control point past neighoring ones
        let new_u = RH.clamp(map2u(new_x), -handleOffset, _vis.size + handleOffset)
        let new_v = RH.clamp(map2v(new_y), -handleOffset, _vis.size + handleOffset)

        let left = _repeater.itemAt(index - 1)
        let right = _repeater.itemAt(index + 1)
        if (left && left.item.x > new_u) {
            new_u = cp_handle.x
            new_x = map2x(cp_handle.x, null)
        }
        if (right && right.item.x < new_u) {
            new_u = cp_handle.x
            new_x = map2x(cp_handle.x, null)
        }

        // Move the actual marker
        cp_handle.x = new_u
        cp_handle.y = new_v

        // Handle symmetry mode, no need to update model as
        // the code does this behind the scenes with the
        // model update below
        if (_root.action.isSymmetric) {
            let mirror = _repeater.itemAt(_repeater.count - index - 1).item
            mirror.x = map2u(-new_x, null)
            mirror.y = map2v(-new_y, null)

        }

        // Return the computed new [x, y] coordinates in [-1, 1] to use on the
        // model side of things
        return [new_x, new_y]
    }

    ColumnLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        // Various controls to configure curve editing
        RowLayout {
            Layout.fillWidth: true

            ComboBox {
                Layout.preferredWidth: 200

                model: ["Piecewise Linear", "Cubic Spline", "Cubic Bezier Spline"]

                Component.onCompleted: function () {
                    currentIndex = find(_root.action.curveType)
                }

                onActivated: function () {
                    _root.action.curveType = currentText
                }
            }

            Button {
                text: "Invert Curve"

                onClicked: _root.action.invertCurve()
            }

            CheckBox {
                text: "Symmetric"

                checked: _root.action.isSymmetric

                onToggled: function () {
                    _root.action.isSymmetric = checked
                }
            }
        }

        // Response curve widget
        Item {
            id: _vis

            property int size: 450
            property int border: 2

            Component.onCompleted: function () {
                action.setWidgetSize(size)
            }

            width: size + 2 * border
            height: size + 2 * border

            // Display the background image
            Image {
                width: _vis.size
                height: _vis.size
                x: _vis.border
                y: _vis.border
                source: "grid.svg"
            }

            // Render the response curve itself not the interactive elements
            Shape {
                id: _curve

                width: _vis.size
                height: _vis.size

                anchors.centerIn: parent

                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: "#808080"
                    strokeWidth: 2
                    fillColor: "transparent"

                    PathPolyline {
                        path: action.linePoints
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onDoubleClicked: function (evt) {
                        action.addControlPoint(
                            2 * (evt.x / width) - 1,
                            -2 * (evt.y / height) + 1
                        )
                    }
                }
            }

            // Render the individual control elements
            Repeater {
                id: _repeater

                model: action.controlPoints

                delegate: Component {
                    // Pick the correct control visualization to load and pass
                    // the repeater reference in
                    Loader {
                        Component.onCompleted: function() {
                            let url = modelData.hasHandles ? "HandleControl.qml" : "PointControl.qml"
                            setSource(url, {"repeater": _repeater})
                        }

                    }
                }
            }
        }

        // Deadzone widget
        Label {
            text: "Deadzone"
        }

        GridLayout {
            Layout.fillWidth: true

            columns: 4

            RangeSlider {
                id: _sliderLow

                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignRight

                from: -1.0
                to: 0.0

                first {
                    onMoved: {
                        deadzone.low = first.value
                    }
                }
                second {
                    onMoved: {
                        deadzone.centerLow = second.value
                    }
                }
            }

            RangeSlider {
                id: _sliderHigh

                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignLeft

                from: 0.0
                to: 1.0

                first {
                    onMoved: {
                        deadzone.centerHigh = first.value
                    }
                }
                second {
                    onMoved: {
                        deadzone.high = second.value
                    }
                }
            }

            FloatSpinBox {
                id: _spinLow

                realValue: -1.0
                minValue: -1.0
                maxValue: _spinCenterLow.realValue

                onRealValueModified: {
                    deadzone.low = realValue
                }
            }
            FloatSpinBox {
                id: _spinCenterLow

                realValue: 0.0
                minValue: _spinLow.realValue
                maxValue: 0.0
            }
            FloatSpinBox {
                id: _spinCenterHigh

                realValue: 0.0
                minValue: 0.0
                maxValue: _spinHigh.realValue
            }
            FloatSpinBox {
                id: _spinHigh

                realValue: 1.0
                minValue: _spinCenterHigh.realValue
                maxValue: 1.0
            }
        }
    }
}