import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 20000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: background1
            source: "slide1.png"
            width: 467; height: 280
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }

        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: background1.bottom

            text: qsTr("Bem-vindo ao Speedy Linux!<br/><br/>"
                       + "A instalação é rápida, simples e automatizada. "
                       + "Em poucos minutos, seu sistema estará pronto para uso.")

            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
