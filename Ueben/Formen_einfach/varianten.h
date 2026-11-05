#ifndef VARIANTEN_H
#define VARIANTEN_H
#include "formen.h"

class GleichseitigesDreieck : public Form {
public:
    GleichseitigesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

class RechtwinkligesDreieck : public Form {
public:
    RechtwinkligesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

class GleichschenkligRechtwinkligesDreieck : public Form {
public:
    GleichschenkligRechtwinkligesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

class SpitzwinkligesDreieck : public Form {
public:
    SpitzwinkligesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

class StumpfwinkligesDreieck : public Form {
public:
    StumpfwinkligesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

class GoldenesDreieck : public Form {
public:
    GoldenesDreieck(int x, int y, int groesse);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, groesse;
};

Form *zusatzformErstellen(int nummer, int x, int y, int groesse);
#endif
