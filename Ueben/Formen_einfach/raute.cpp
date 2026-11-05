#include "formen.h"
#include <QPolygon>

Raute::Raute(int x, int y, int breite, int hoehe)
    : x(x), y(y), breite(breite), hoehe(hoehe) {}

void Raute::zeichnen(QPainter &maler) const
{
    QPolygon punkte{QPoint(x + breite / 2, y), QPoint(x + breite, y + hoehe / 2),
                    QPoint(x + breite / 2, y + hoehe), QPoint(x, y + hoehe / 2)};
    maler.drawPolygon(punkte);
}
