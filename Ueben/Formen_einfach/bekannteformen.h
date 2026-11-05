#ifndef BEKANNTEFORMEN_H
#define BEKANNTEFORMEN_H

#include "formen.h"

// Klassische geometrische Formen mit Mittelpunkt und Größe.
class EinfacheForm : public Form
{
public:
    EinfacheForm(int x, int y, int groesse) : x(x), y(y), groesse(groesse) {}
protected:
    int x, y, groesse;
};

class Halbkreis : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

class Viertelkreis : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

class Ring : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

class Fuenfeck : public RegelmaessigesPolygon
{
public:
    Fuenfeck(int x, int y, int radius);
};

class Achteck : public RegelmaessigesPolygon
{
public:
    Achteck(int x, int y, int radius);
};

class Drachenviereck : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

class Kreisbogen : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

class Kreisabschnitt : public EinfacheForm
{
public:
    using EinfacheForm::EinfacheForm;
    void zeichnen(QPainter &maler) const override;
};

#endif
