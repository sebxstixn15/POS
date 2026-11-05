#include "varianten.h"
#include <QPolygonF>

RechtwinkligesDreieck::RechtwinkligesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void RechtwinkligesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 0),
                    QPointF(x + groesse * 0, y + groesse * 0.75)};
    maler.drawPolygon(punkte);
}
