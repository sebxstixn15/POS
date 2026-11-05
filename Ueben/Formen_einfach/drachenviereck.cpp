#include "bekannteformen.h"
#include <QPolygon>

void Drachenviereck::zeichnen(QPainter &maler) const
{
    QPolygon punkte{QPoint(x, y - groesse),
                    QPoint(x + groesse / 2, y),
                    QPoint(x, y + groesse / 2),
                    QPoint(x - groesse / 2, y)};
    maler.drawPolygon(punkte);
}
