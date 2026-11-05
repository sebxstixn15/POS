#include "bekannteformen.h"

void Ring::zeichnen(QPainter &maler) const
{
    maler.drawEllipse(x - groesse, y - groesse, 2 * groesse, 2 * groesse);
    int innen = groesse / 2;
    maler.drawEllipse(x - innen, y - innen, 2 * innen, 2 * innen);
}
