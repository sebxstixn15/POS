#include "formen.h"
#include <QPolygonF>
#include <cmath>

Stern::Stern(int x, int y, int radius, int spitzen)
    : x(x), y(y), radius(radius), spitzen(spitzen) {}

void Stern::zeichnen(QPainter &maler) const
{
    const double pi = std::acos(-1.0);
    QPolygonF punkte;
    for (int i = 0; i < 2 * spitzen; ++i) {
        double winkel = -pi / 2 + pi * i / spitzen;
        int punktRadius = (i % 2 == 0) ? radius : radius / 2;
        punkte << QPointF(x + punktRadius * std::cos(winkel),
                          y + punktRadius * std::sin(winkel));
    }
    maler.drawPolygon(punkte);
}
