#include "varianten.h"
#include <QPolygonF>

SpitzwinkligesDreieck::SpitzwinkligesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void SpitzwinkligesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 0.9),
                    QPointF(x + groesse * 0.4, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 0.75)};
    maler.drawPolygon(punkte);
}
