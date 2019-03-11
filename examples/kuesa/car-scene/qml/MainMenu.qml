/*
    IdleDemoAnimation.qml

    This file is part of Kuesa.

    Copyright (C) 2019 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.com
    Author: Mike Krus <mike.krus@kdab.com>

    Licensees holding valid proprietary KDAB Kuesa licenses may use this file in
    accordance with the Kuesa Enterprise License Agreement provided with the Software in the
    LICENSE.KUESA.ENTERPRISE file.

    Contact info@kdab.com if any conditions of this licensing are not clear to you.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import QtQuick 2.11
import QtQuick.Controls 1.4
import "controls" as Controls
import QtGraphicalEffects 1.0

Item {
    id: root
    property alias carSpeed: speedC.value
    property alias openLeftDoor: openLeftDoorSwitch.checked
    property alias openRightDoor: openRightDoorSwitch.checked
    property alias openHood: openHoodSwitch.checked
    property string environmentMap: {
        if (envPinkSunrise.checked) return "pink_sunrise"
        if (envNeuerZollhof.checked) return "neuer_zollhof"
        if (envStudioSmall04.checked) return "kdab-studiosky-small"
    }
    property double environmentExposure: {
        if (envPinkSunrise.checked) return 0.0
        if (envNeuerZollhof.checked) return 0.0
        if (envStudioSmall04.checked) return -1.5
    }
    property alias showSkybox: showSkyboxSwitch.checked
    property alias exposure: exposureSlider.value
    property alias useOpacityMask: useOpacityMaskSwitch.checked
    property color carBaseColorFactor: "white"
    property alias idleAnimationRunning: idleAnimation.running


    function reset() {
        speedC.value = 0
        openLeftDoorSwitch.checked = false
        openRightDoorSwitch.checked = false
        openHoodSwitch.checked = false
        useOpacityMaskSwitch.checked = false
        showSkyboxSwitch.checked = false
    }

    Item {
        id: menu

        property int expandedWidth: Math.min(Controls.SharedAttributes.ldpi * 3, mainRoot.width / 3)
        property real switchWidth: Math.floor( Math.min((expandedWidth - Controls.SharedAttributes.defaultSpacing * 4) / 3, Controls.SharedAttributes.ldpi * 1.3) ) - 1
        property real radioButtonWidth: Math.floor( Math.min( (expandedWidth - Controls.SharedAttributes.defaultSpacing * 4) / 3, Controls.SharedAttributes.ldpi * 1.3) ) - 10

        width: menuIcon.expanded ? expandedWidth : 0
        height: parent.height
        clip: true
        visible: width > 0

        Behavior on width { NumberAnimation {duration: 500; easing.type: Easing.InOutQuad } }

        Component {
            id: blurBg

            Item {
                Rectangle {
                    id: cliper

                    property real scaleReducer: 2.5
                    width: menu.expandedWidth / scaleReducer
                    height: mainRoot.height / scaleReducer
                    clip: true

                    ShaderEffectSource {
                        id: copy3D
                        width: baseUI.width / cliper.scaleReducer
                        height: baseUI.height / cliper.scaleReducer
                        sourceItem: baseUI
                        textureSize: Qt.size(width / cliper.scaleReducer, height / cliper.scaleReducer)
                        sourceRect : Qt.rect(0, 0, width * cliper.scaleReducer, height * cliper.scaleReducer)
                        samples: 1
                        mipmap: false
                    }
                }

                FastBlur {
                    anchors.fill: cliper
                    source: cliper
                    radius: 140/cliper.scaleReducer
                    transform: Scale {
                        origin.x: 0
                        origin.y: 0
                        xScale: mainRoot.height / cliper.height
                        yScale: xScale
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#40202020"
                    }
                }

                Image {
                    fillMode: Image.Tile
                    source: "noise.png"
                    width: cliper.width * (mainRoot.height / cliper.height)
                    height: mainRoot.height
                    opacity: 0.8
                }
            }
        }

        Component {
            id: noiseBg

            Rectangle {
                anchors.fill: parent
                color: "#33000000"

                Image {
                    fillMode: Image.Tile
                    source: "noise.png"
                    anchors.fill: parent
                    opacity: 0.8
                }
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: blurBg
        }

        MouseArea {
            width: childrenRect.width
            height: parent.height

            Flickable {
                y: Controls.SharedAttributes.ldpi * 0.75
                width: menu.expandedWidth - Math.ceil(Controls.SharedAttributes.ldpi / 10) * 2
                x: Math.ceil(Controls.SharedAttributes.ldpi / 10)
                height: parent.height - y
                clip: true
                contentHeight: controlArea.height

                interactive: height < contentHeight

                Column {
                    x: 1
                    width: parent.width - 2
                    id: controlArea

                    Controls.GroupBox {
                        width: parent.width
                        layer.enabled: true
                        padding: 1

                        Controls.StyledLabel {
                            text: "Car Control"
                            font.weight: Font.ExtraLight
                            font.pixelSize: Controls.SharedAttributes.largeFontSize
                        }

                        Rectangle {
                            width: parent.width - 2
                            height: Math.ceil(Controls.SharedAttributes.ldpi / 150)
                            color: "#70ffffff"
                        }

                        Controls.LabeledSlider {
                            id: speedC
                            text: "Car Wheels Speed"
                            width: parent.width - 2
                            minimumValue: 0
                            maximumValue: 8
                        }

                        Item {
                            id: spacer
                            height: 1
                            width: 1
                        }

                        Flow {
                            width: menu.expandedWidth - 2
                            spacing: parent.spacing

                            Controls.LabeledSwitch {
                                id: openHoodSwitch
                                text: "Open Hood"
                                checked: false
                                width: menu.switchWidth
                            }

                            Controls.LabeledSwitch {
                                id: openLeftDoorSwitch
                                text: "Left Door"
                                checked: false
                                width: menu.switchWidth
                            }

                            Controls.LabeledSwitch {
                                id: openRightDoorSwitch
                                text: "Right Door"
                                checked: false
                                width: menu.switchWidth
                            }
                        }
                    }

                    Item {
                        height: Controls.SharedAttributes.ldpi / 10
                        width: 1
                    }

                    Controls.GroupBox {
                        width: parent.width
                        layer.enabled: true
                        padding: 1

                        Controls.StyledLabel {
                            text: "Scene Control"
                            font.pixelSize: Controls.SharedAttributes.largeFontSize
                            font.weight: Font.ExtraLight
                        }

                        Rectangle {
                            width: parent.width - 2
                            height: Math.ceil(Controls.SharedAttributes.ldpi / 150)
                            color: "#70ffffff"
                        }

                        Controls.LabeledSlider {
                            id: exposureSlider
                            text: "Exposure: " + parseFloat(Math.round(exposureSlider.value * 100) / 100).toFixed(2)
                            minimumValue: -5.0
                            maximumValue: 5
                            value: 2.5
                            width: parent.width - 2
                        }

                        Item {
                            id: spacer2
                            height: 1
                            width: 1
                        }

                        Controls.StyledLabel {
                            text: "Environment"
                        }

                        Flow {
                            width: menu.expandedWidth - 2
                            spacing: parent.spacing

                            ExclusiveGroup { id: radioButonsGroup }

                            Controls.LabeledRadioButton {
                                id: envPinkSunrise
                                width: menu.radioButtonWidth
                                text: "Pink Sunrise"
                                exclusiveGroup: radioButonsGroup
                                checked: true
                            }

                            Controls.LabeledRadioButton {
                                id: envNeuerZollhof
                                width: menu.radioButtonWidth
                                text: "Neuer Zollhof"
                                exclusiveGroup: radioButonsGroup
                            }

                            Controls.LabeledRadioButton {
                                id: envStudioSmall04
                                width: menu.radioButtonWidth
                                text: "KDAB Studio"
                                exclusiveGroup: radioButonsGroup
                            }
                        }

                        Row {
                            spacing: parent.spacing
                            Controls.LabeledSwitch {
                                id: showSkyboxSwitch
                                text: "Show Skybox"
                                checked: false
                                width: menu.switchWidth
                            }

                            Controls.LabeledSwitch {
                                id: useOpacityMaskSwitch
                                text: "Use OpacityMask"
                                checked: false
                                width: menu.switchWidth
                            }
                        }
                    }

                    Item {
                        height: Controls.SharedAttributes.ldpi / 10
                        width: 1
                    }

                    Controls.GroupBox {
                        width: parent.width
                        layer.enabled: true
                        padding: 1

                        Controls.StyledLabel {
                            text: "Car Color"
                            font.pixelSize: Controls.SharedAttributes.largeFontSize
                            font.weight: Font.ExtraLight
                        }

                        Rectangle {
                            width: parent.width - 2
                            height: Math.ceil(Controls.SharedAttributes.ldpi / 150)
                            color: "#70ffffff"
                        }

                        Controls.LabeledSlider {
                            id: redColor
                            text: "Red: " + parseFloat(Math.round(redColor.value * 255).toFixed(2))
                            value: sceneContent.carBaseColorFactor.r
                            onValueChanged: if (value !== sceneContent.carBaseColorFactor.r)
                                                sceneContent.carBaseColorFactor = Qt.rgba(redColor.value, greenColor.value, blueColor.value)
                            width: parent.width - 2
                        }

                        Controls.LabeledSlider {
                            id: greenColor
                            text: "Green: " + parseFloat(Math.round(greenColor.value * 255).toFixed(2))
                            value: sceneContent.carBaseColorFactor.g
                            onValueChanged: if (value !== sceneContent.carBaseColorFactor.g)
                                                sceneContent.carBaseColorFactor = Qt.rgba(redColor.value, greenColor.value, blueColor.value)
                            width: parent.width - 2
                        }

                        Controls.LabeledSlider {
                            id: blueColor
                            text: "Blue: " + parseFloat(Math.round(blueColor.value * 255).toFixed(2))
                            value: sceneContent.carBaseColorFactor.b
                            onValueChanged: if (value !== sceneContent.carBaseColorFactor.b)
                                                sceneContent.carBaseColorFactor = Qt.rgba(redColor.value, greenColor.value, blueColor.value)
                            width: parent.width - 2
                        }
                    }


                    Item {
                        height: Controls.SharedAttributes.ldpi / 10
                        width: 10
                    }
                }
            }
        }
    }

    Image {
        id: edge
        source: "edge.png"
        anchors.left: menu.right
        anchors.leftMargin: -1
        height: parent.height
    }

    Item {
        id: menuIcon
        width: Math.ceil(Controls.SharedAttributes.ldpi / 3.5)
        height: Math.ceil(width * 0.9)
        x: width / 2
        y: Math.ceil(width * 0.75)

        property bool expanded: false

        MouseArea {
            anchors.fill: parent
            anchors.margins: -width
            onClicked: parent.expanded = !parent.expanded
        }

        Rectangle {
            id: rect1
            width: parent.width * (1 + (-rotation / 200))
            y: -rotation / height
            height:  Math.ceil(width / 6)
            radius: height
            color: "#cccccc"
            rotation: parent.expanded? -0.25 * Controls.SharedAttributes.ldpi : 0

            Behavior on rotation { NumberAnimation {duration: 250; easing.type: Easing.OutCirc } }
        }

        Rectangle {
            x: parent.expanded ? -parent.x - height : 0
            width: parent.expanded ? rect1.height : parent.width
            height:  rect1.height
            anchors.verticalCenter: parent.verticalCenter
            radius: height
            color: "#cccccc"

            Behavior on x { NumberAnimation {duration: 300; easing.type: Easing.InOutQuad } }
            Behavior on width { NumberAnimation {duration: 200; easing.type: Easing.InOutQuad } }
        }

        Rectangle {
            width: parent.width * (1 + (rotation / 200))
            height:  rect1.height
            anchors.bottom: parent.bottom
            radius: height
            color: "#cccccc"
            rotation: -rect1.rotation
            y: -rotation/height
        }
    }

    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onPressed: {
            idleAnimation.restartTimer()
            mouse.accepted = false
        }
        onPositionChanged: {
            idleAnimation.restartTimer()
            mouse.accepted = false
        }
    }

    // Idle Animation
    IdleDemoAnimation {
        id: idleAnimation
        running: true
        anchors.fill: parent

        onReset: root.reset()
    }
}
