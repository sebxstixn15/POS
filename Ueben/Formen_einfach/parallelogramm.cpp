#include "formen.h"
#include <QPolygon>

Parallelogramm::Parallelogramm(int x, int y, int breite, int hoehe, int versatz)
    : x(x), y(y), breite(breite), hoehe(hoehe), versatz(versatz) {}

void Parallelogramm::zeichnen(QPainter &maler) const
{
    QPolygon punkte{QPoint(x + versatz, y), QPoint(x + versatz + breite, y),
                    QPoint(x + breite, y + hoehe), QPoint(x, y + hoehe)};
    maler.drawPolygon(punkte);
}
