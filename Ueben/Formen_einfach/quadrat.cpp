#include "formen.h"

// Ein Quadrat ist ein Rechteck mit gleich breiten Seiten.
Quadrat::Quadrat(int x, int y, int seite)
    : Rechteck(x, y, seite, seite) {}
