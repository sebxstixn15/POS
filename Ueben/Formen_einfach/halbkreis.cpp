#include "bekannteformen.h"

void Halbkreis::zeichnen(QPainter &maler) const
{
    maler.drawPie(x - groesse, y - groesse, 2 * groesse, 2 * groesse,
                  0, 180 * 16);
}
