#include "formen.h"
#include <QPolygon>

Dreieck::Dreieck(int x, int y, int breite, int hoehe)
    : x(x), y(y), breite(breite), hoehe(hoehe) {}

void Dreieck::zeichnen(QPainter &maler) const
{
    QPolygon punkte{QPoint(x + breite / 2, y), QPoint(x + breite, y + hoehe),
                    QPoint(x, y + hoehe)};
    maler.drawPolygon(punkte);
}
