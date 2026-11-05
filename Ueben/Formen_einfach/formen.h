#ifndef FORMEN_H
#define FORMEN_H

#include <QPainter>

// Alle Formen können sich selbst zeichnen.
class Form
{
public:
    virtual ~Form() = default;
    virtual void zeichnen(QPainter &maler) const = 0;
};

class Rechteck : public Form
{
public:
    Rechteck(int x, int y, int breite, int hoehe);
    void zeichnen(QPainter &maler) const override;
protected:
    int x, y, breite, hoehe;
};

class Quadrat : public Rechteck
{
public:
    Quadrat(int x, int y, int seite);
};

class Kreis : public Form
{
public:
    Kreis(int x, int y, int radius);
    void zeichnen(QPainter &maler) const override;
protected:
    int x, y, radius;
};

class Kreissegment : public Kreis
{
public:
    Kreissegment(int x, int y, int radius, int startGrad, int winkelGrad);
    void zeichnen(QPainter &maler) const override;
private:
    int startGrad, winkelGrad;
};

class Trapez : public Form
{
public:
    Trapez(int x, int y, int obereBreite, int untereBreite, int hoehe);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, obereBreite, untereBreite, hoehe;
};

class Parallelogramm : public Form
{
public:
    Parallelogramm(int x, int y, int breite, int hoehe, int versatz);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, breite, hoehe, versatz;
};

class Dreieck : public Form
{
public:
    Dreieck(int x, int y, int breite, int hoehe);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, breite, hoehe;
};

class Raute : public Form
{
public:
    Raute(int x, int y, int breite, int hoehe);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, breite, hoehe;
};

class RegelmaessigesPolygon : public Form
{
public:
    RegelmaessigesPolygon(int x, int y, int radius, int ecken);
    void zeichnen(QPainter &maler) const override;
protected:
    int x, y, radius, ecken;
};

class Sechseck : public RegelmaessigesPolygon
{
public:
    Sechseck(int x, int y, int radius);
};

class Stern : public Form
{
public:
    Stern(int x, int y, int radius, int spitzen);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, radius, spitzen;
};

class Ellipse : public Form
{
public:
    Ellipse(int x, int y, int breite, int hoehe);
    void zeichnen(QPainter &maler) const override;
private:
    int x, y, breite, hoehe;
};

#endif
