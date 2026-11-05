#include "formen.h"
#include <QPolygonF>
#include <cmath>

RegelmaessigesPolygon::RegelmaessigesPolygon(int x, int y, int radius, int ecken)
    : x(x), y(y), radius(radius), ecken(ecken) {}

void RegelmaessigesPolygon::zeichnen(QPainter &maler) const
{
    const double pi = std::acos(-1.0);
    QPolygonF punkte;
    for (int i = 0; i < ecken; ++i) {
        double winkel = -pi / 2 + 2 * pi * i / ecken;
        punkte << QPointF(x + radius * std::cos(winkel),
                          y + radius * std::sin(winkel));
    }
    maler.drawPolygon(punkte);
}
