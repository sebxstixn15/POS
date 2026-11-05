#include "formen.h"

Ellipse::Ellipse(int x, int y, int breite, int hoehe)
    : x(x), y(y), breite(breite), hoehe(hoehe) {}

void Ellipse::zeichnen(QPainter &maler) const
{
    maler.drawEllipse(x, y, breite, hoehe);
}
