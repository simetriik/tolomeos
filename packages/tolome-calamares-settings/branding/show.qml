/* Diaporama d'installation de Tɔlɔmɛ.
 * Structure reprise du diaporama de calamares-settings-debian (GPL-2+). */

import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 15000
        repeat: true
        running: presentation.activatedInCalamares
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: photo1
            source: "slide1.png"
            width: 640; height: 330
            fillMode: Image.PreserveAspectCrop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
        }
        Text {
            anchors.horizontalCenter: photo1.horizontalCenter
            anchors.top: photo1.bottom
            anchors.topMargin: 16
            text: qsTr("Bienvenue dans Tɔlɔmɛ.<br/>" +
                  "La suite de l'installation est automatique et prendra quelques minutes.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Image {
            id: photo2
            source: "slide2.png"
            width: 640; height: 330
            fillMode: Image.PreserveAspectCrop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
        }
        Text {
            anchors.horizontalCenter: photo2.horizontalCenter
            anchors.top: photo2.bottom
            anchors.topMargin: 16
            text: qsTr("Un système pensé pour le Bénin et l'Afrique de l'Ouest :<br/>" +
                  "français par défaut, fuseau Africa/Porto-Novo, clavier fon.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Image {
            id: photo3
            source: "slide3.png"
            width: 640; height: 330
            fillMode: Image.PreserveAspectCrop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
        }
        Text {
            anchors.horizontalCenter: photo3.horizontalCenter
            anchors.top: photo3.bottom
            anchors.topMargin: 16
            text: qsTr("Pour écrire en fon, changez de disposition de clavier<br/>" +
                  "avec Super + Espace.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
        }
    }
}
