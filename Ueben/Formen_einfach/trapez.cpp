#include "formen.h"
#include <QPolygon>

Trapez::Trapez(int x, int y, int obereBreite, int untereBreite, int hoehe)
    : x(x), y(y), obereBreite(obereBreite), untereBreite(untereBreite), hoehe(hoehe) {}

void Trapez::zeichnen(QPainter &maler) const
{
    int abstand = (untereBreite - obereBreite) / 2;
    QPolygon punkte{QPoint(x + abstand, y), QPoint(x + abstand + obereBreite, y),
                    QPoint(x + untereBreite, y + hoehe), QPoint(x, y + hoehe)};
    maler.drawPolygon(punkte);
}
