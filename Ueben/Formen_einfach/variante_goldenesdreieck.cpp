#include "varianten.h"
#include <QPolygonF>

GoldenesDreieck::GoldenesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void GoldenesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 1.5388),
                    QPointF(x + groesse * 0.5, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 1.5388)};
    maler.drawPolygon(punkte);
}
