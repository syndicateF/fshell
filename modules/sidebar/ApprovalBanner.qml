import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// Banner for pending tool approvals
Item {
    id: root
    
    required property var approvals
    
    signal approve(string id)
    signal reject(string id)
    
    implicitHeight: layout.implicitHeight
    
    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Appearance.spacing.small
        
        Repeater {
            model: root.approvals
            
            delegate: StyledRect {
                id: approvalItem
                required property var modelData
                required property int index
                
                Layout.fillWidth: true
                radius: Appearance.rounding.normal
                color: Colours.palette.m3secondaryContainer
                
                implicitHeight: approvalLayout.implicitHeight + Appearance.padding.normal * 2
                
                ColumnLayout {
                    id: approvalLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.small
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small
                        
                        StyledText {
                            text: "⚠️"
                            font.pointSize: Appearance.font.size.normal
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("AI wants to use: ") + approvalItem.modelData.name
                            font.pointSize: Appearance.font.size.normal
                            font.weight: 600
                            color: Colours.palette.m3onSecondaryContainer
                            elide: Text.ElideRight
                        }
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: approvalItem.modelData.preview
                        wrapMode: Text.Wrap
                        font.pointSize: Appearance.font.size.small
                        font.family: Appearance.font.family.mono
                        color: Colours.palette.m3onSecondaryContainer
                        opacity: 0.9
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: Appearance.spacing.normal
                        
                        TextButton {
                            text: qsTr("Reject")
                            onClicked: root.reject(approvalItem.modelData.id)
                        }
                        
                        TextButton {
                            text: qsTr("Allow")
                            type: TextButton.Filled
                            onClicked: root.approve(approvalItem.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
