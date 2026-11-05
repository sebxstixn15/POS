#include "formen.h"

Kreissegment::Kreissegment(int x, int y, int radius, int startGrad, int winkelGrad)
    : Kreis(x, y, radius), startGrad(startGrad), winkelGrad(winkelGrad) {}

void Kreissegment::zeichnen(QPainter &maler) const
{
    // Qt misst Winkel in Sechzehntelgrad. 0° zeigt nach rechts, 90° nach oben.
    maler.drawPie(x - radius, y - radius, 2 * radius, 2 * radius,
                  startGrad * 16, winkelGrad * 16);
}
