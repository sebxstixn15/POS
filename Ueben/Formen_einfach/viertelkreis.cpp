#include "bekannteformen.h"

void Viertelkreis::zeichnen(QPainter &maler) const
{
    maler.drawPie(x - groesse, y - groesse, 2 * groesse, 2 * groesse,
                  0, 90 * 16);
}
