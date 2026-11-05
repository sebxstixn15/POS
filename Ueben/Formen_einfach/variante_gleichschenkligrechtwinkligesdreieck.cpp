#include "varianten.h"
#include <QPolygonF>

GleichschenkligRechtwinkligesDreieck::GleichschenkligRechtwinkligesDreieck(int x, int y, int groesse)
    : x(x), y(y), groesse(groesse) {}

void GleichschenkligRechtwinkligesDreieck::zeichnen(QPainter &maler) const
{
    QPolygonF punkte{QPointF(x + groesse * 0, y + groesse * 0),
                    QPointF(x + groesse * 1, y + groesse * 0),
                    QPointF(x + groesse * 0, y + groesse * 1)};
    maler.drawPolygon(punkte);
}
