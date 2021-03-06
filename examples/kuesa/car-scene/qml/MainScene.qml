/*
    MainScene.qml

    This file is part of Kuesa.

    Copyright (C) 2018-2019 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.com
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

import Qt3D.Core 2.10
import Qt3D.Render 2.11
import Qt3D.Input 2.0
import Qt3D.Extras 2.11
import Qt3D.Animation 2.10

import Kuesa 1.0 as Kuesa
import Kuesa.Effects 1.0 as Effects

import QtQuick 2.11 as QQ2

Kuesa.SceneEntity {
    id: scene

    property int screenWidth
    property int screenHeight

    property bool animated: false
    property bool explodedView
    property int carSpeed
    property bool openLeftDoor
    property bool openRightDoor
    property bool openHood
    property bool enableClipping
    property string environmentMap: "pink_sunrise"
    property double environmentExposure: 0.0
    property alias showSkybox: skybox.enabled
    property double exposure: 0.0
    property bool useOpacityMask: false
    property color carBaseColorFactor: "white"
    property bool es2: _isES2

    Entity {
        id: d
        property string envMapFormat: (Qt.platform.os == "osx" || Qt.platform.os == "ios" || Qt.platform.os == "android" || es2) ? "_16f" : ""
        property Camera sweepCam: null

        function flipAnimation(open, animation) {
            if (open) {
                animation.clock.playbackRate = 1
                if (animation.normalizedTime > 0)
                    animation.normalizedTime = 1 - animation.normalizedTime
                animation.start()
            } else {
                animation.clock.playbackRate = -1
                if (animation.normalizedTime > 0 && animation.normalizedTime < 1)
                    animation.normalizedTime = 1 - animation.normalizedTime
                animation.start()
            }
        }
    }

    QQ2.Binding {
        target: carMaterial.node
        property: "baseColorFactor"
        value: scene.carBaseColorFactor
    }

    Kuesa.Asset {
        id: carMaterial
        collection: scene.materials
        name: "Mat_CarPaint"
        onNodeChanged: scene.carBaseColorFactor = node.baseColorFactor
    }

    Kuesa.AnimationPlayer {
        id: hoodAnimator
        sceneEntity: scene
        clock: Clock { }
        clip: "HoodAction"
    }

    Kuesa.AnimationPlayer {
        id: leftDoorAnimator
        sceneEntity: scene
        clock: Clock { }
        clip: "DoorLAction"
    }

    Kuesa.AnimationPlayer {
        id: rightDoorAnimator
        sceneEntity: scene
        clock: Clock { }
        clip: "DoorRAction"
    }

    Kuesa.AnimationPlayer {
        id: sweepCamCenterAnimation
        sceneEntity: scene
        clip: "SweepCamCenterAction"
        loops: Kuesa.AnimationPlayer.Infinite
        running: scene.animated
    }
    Kuesa.AnimationPlayer {
        id: sweepCamPitchAnimation
        sceneEntity: scene
        clip: "SweepCamPitchAction"
        loops: Kuesa.AnimationPlayer.Infinite
        running: scene.animated
    }

    NodeInstantiator {
        id: wheelAnimators
        property var clock: Clock { playbackRate: scene.carSpeed / 2 }

        model: [ "WheelFLDriveAction", "WheelFRDriveAction", "WheelBLDriveAction", "WheelBRDriveAction" ]

        delegate: Kuesa.AnimationPlayer {
            sceneEntity: scene
            clip: modelData
            clock: wheelAnimators.clock
            running: scene.carSpeed > 0
            loops: Kuesa.AnimationPlayer.Infinite
        }
    }

    Kuesa.Asset {
        id: sweepCam
        collection: scene.cameras
        name: "SweepCam"
    }

    QQ2.Binding {
        target: sweepCam.node
        property: "aspectRatio"
        value: mainCamera.aspectRatio
    }

    onOpenHoodChanged: {
        d.flipAnimation(openHood, hoodAnimator)
    }

    onOpenLeftDoorChanged: {
        d.flipAnimation(openLeftDoor, leftDoorAnimator)
    }

    onOpenRightDoorChanged: {
        d.flipAnimation(openRightDoor, rightDoorAnimator)
    }

    // let this point light wander around with the camera to create some shiny lighting
    Entity {
        id: pointLightEntity
        parent: frameGraph.camera
        components: [
            PointLight {
                constantAttenuation: 1.0
                linearAttenuation: 0.0
                quadraticAttenuation: 0.0
            }
        ]
    }

    components: [
        RenderSettings {
            // FrameGraph
            activeFrameGraph: Kuesa.ForwardRenderer {
                id: frameGraph
                camera: scene.animated && sweepCam.node ? sweepCam.node : mainCamera
                postProcessingEffects: useOpacityMask ? [opacityMaskEffect] : []
                backToFrontSorting: true
            }
        },
        InputSettings { },
        EnvironmentLight {
            irradiance: TextureLoader {
                source: _assetsPrefix + environmentMap + d.envMapFormat + "_irradiance" + ((!scene.es2) ? ".dds" : "_es2.dds")
                wrapMode {
                    x: WrapMode.ClampToEdge
                    y: WrapMode.ClampToEdge
                }
                generateMipMaps: false
            }
            specular: TextureLoader {
                source: _assetsPrefix + environmentMap + d.envMapFormat + "_specular" + ((!scene.es2) ? ".dds" : "_es2.dds")
                wrapMode {
                    x: WrapMode.ClampToEdge
                    y: WrapMode.ClampToEdge
                }
                generateMipMaps: false
            }
        }
    ]

    Effects.OpacityMask {
        id: opacityMaskEffect
        mask: TextureLoader {
            source: "qrc:/opacity_mask.png";
            generateMipMaps: false
        }
        premultipliedAlpha: true // This is what Scene3D/QtQuick expects
    }

    QQ2.Binding {
        target: frameGraph.camera
        property: "exposure"
        value: scene.exposure + scene.environmentExposure
    }

    Camera {
        id: mainCamera
        fieldOfView: scene.explodedView ? 55 : 35
        position: Qt.vector3d(4.5, 1.5, 4.5)
        upVector: Qt.vector3d(0, 1, 0)
        viewCenter: Qt.vector3d(0, .5, 0)

        QQ2.Behavior on fieldOfView { QQ2.NumberAnimation { duration: 750; easing.type: QQ2.Easing.OutQuad } }
    }

    CarCameraController {
        camera: mainCamera
        enabled: !scene.animated
    }

    // Loads GLTF 2.0 asset
    Kuesa.GLTF2Importer {
        sceneEntity: scene
        source: _assetsPrefix + "DodgeViper" + _modelSuffix + ".gltf"
    }

    Kuesa.Skybox {
        id: skybox
        baseName: _assetsPrefix + environmentMap + "_skybox"
        extension: ".dds"
    }
}
