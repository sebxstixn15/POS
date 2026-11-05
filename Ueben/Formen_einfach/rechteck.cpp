#include "formen.h"

Rechteck::Rechteck(int x, int y, int breite, int hoehe)
    : x(x), y(y), breite(breite), hoehe(hoehe) {}

void Rechteck::zeichnen(QPainter &maler) const
{
    maler.drawRect(x, y, breite, hoehe);
}
