#include "bekannteformen.h"

// Kreisbogen mit gerader Sehne: ein echter Kreisabschnitt.
void Kreisabschnitt::zeichnen(QPainter &maler) const
{
    maler.drawChord(x - groesse, y - groesse, 2 * groesse, 2 * groesse,
                    0, 90 * 16);
}
