#include "varianten.h"
#include <QPolygonF>

StumpfwinkligesDreieck::StumpfwinkligesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void StumpfwinkligesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 0),
                    QPointF(x + groesse * 0.25, y + groesse * 0.3)};
    maler.drawPolygon(punkte);
}
