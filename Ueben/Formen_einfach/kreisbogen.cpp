#include "bekannteformen.h"

void Kreisbogen::zeichnen(QPainter &maler) const
{
    maler.drawArc(x - groesse, y - groesse, 2 * groesse, 2 * groesse,
                  0, 180 * 16);
}
