import QtQuick

Item {
  id: root
  property real radius: Math.min(width, height) / 2
  property color color: "#B5595D"

  onWidthChanged: cutRect.requestPaint()
  onHeightChanged: cutRect.requestPaint()
  onRadiusChanged: cutRect.requestPaint()
  onColorChanged: cutRect.requestPaint()

  Canvas {
    id: cutRect
    anchors.fill: parent

    onPaint: {
      var ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);

      var cut = root.radius;
      ctx.beginPath();
      ctx.moveTo(cut, 0);
      ctx.lineTo(width - cut, 0);
      ctx.lineTo(width, cut);
      ctx.lineTo(width, height - cut);
      ctx.lineTo(width - cut, height);
      ctx.lineTo(cut, height);
      ctx.lineTo(0, height - cut);
      ctx.lineTo(0, cut);
      ctx.closePath();

      ctx.fillStyle = root.color;
      ctx.fill();
    }
  }
}
