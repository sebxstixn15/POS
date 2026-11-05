#include "formen.h"

Kreis::Kreis(int x, int y, int radius)
    : x(x), y(y), radius(radius) {}

void Kreis::zeichnen(QPainter &maler) const
{
    maler.drawEllipse(x - radius, y - radius, 2 * radius, 2 * radius);
}
