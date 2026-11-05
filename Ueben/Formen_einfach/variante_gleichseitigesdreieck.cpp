#include "varianten.h"
#include <QPolygonF>

GleichseitigesDreieck::GleichseitigesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void GleichseitigesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 0.866),
                    QPointF(x + groesse * 0.5, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 0.866)};
    maler.drawPolygon(punkte);
}
