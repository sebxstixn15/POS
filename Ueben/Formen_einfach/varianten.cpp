#include "varianten.h"

Form *zusatzformErstellen(int nummer, int x, int y, int groesse)
{
    switch (nummer) {
    case 0: return new GleichseitigesDreieck(x, y, groesse);
    case 1: return new RechtwinkligesDreieck(x, y, groesse);
    case 2: return new GleichschenkligRechtwinkligesDreieck(x, y, groesse);
    case 3: return new SpitzwinkligesDreieck(x, y, groesse);
    case 4: return new StumpfwinkligesDreieck(x, y, groesse);
    case 5: return new GoldenesDreieck(x, y, groesse);
    default: return nullptr;
    }
}
