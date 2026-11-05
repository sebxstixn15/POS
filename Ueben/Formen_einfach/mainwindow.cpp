#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "varianten.h"
#include "bekannteformen.h"

#include <QComboBox>
#include <QMessageBox>
#include <QPainter>
#include <QPushButton>

Zeichenflaeche::Zeichenflaeche(QWidget *parent) : QWidget(parent)
{
    setMinimumSize(600, 450);
    setAutoFillBackground(true);
}

Zeichenflaeche::~Zeichenflaeche()
{
    for (Form *form : formen)
        delete form;
}

void Zeichenflaeche::formHinzufuegen(Form *form)
{
    formen.append(form);
    update();
}

void Zeichenflaeche::paintEvent(QPaintEvent *)
{
    QPainter maler(this);
    maler.setRenderHint(QPainter::Antialiasing);
    maler.setPen(QPen(Qt::black, 2));
    for (Form *form : formen)
        form->zeichnen(maler);
}

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    zeichenflaeche = new Zeichenflaeche(this);
    ui->verticalLayout->addWidget(zeichenflaeche);

    ui->auswahl->addItems({"Rechteck", "Quadrat", "Kreis", "Kreissegment",
                           "Trapez", "Parallelogramm", "Dreieck", "Sechseck",
                           "Raute", "Polygon", "Stern", "Ellipse"});
    ui->auswahl->addItems({"Gleichseitiges Dreieck", "Rechtwinkliges Dreieck",
                           "Gleichschenklig-rechtwinkliges Dreieck", "Spitzwinkliges Dreieck",
                           "Stumpfwinkliges Dreieck", "Goldenes Dreieck"});
    ui->auswahl->addItems({"Halbkreis", "Viertelkreis", "Ring", "Fünfeck",
                           "Achteck", "Drachenviereck", "Kreisbogen", "Kreisabschnitt"});
    connect(ui->zeichnenButton, &QPushButton::clicked, this, &MainWindow::zeichnen);
    connect(ui->auswahl, &QComboBox::currentTextChanged,
            this, &MainWindow::hilfeAktualisieren);
    hilfeAktualisieren();
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::hilfeAktualisieren()
{
    QString typ = ui->auswahl->currentText();
    QString format;
    QString beispiel;
    if (ui->auswahl->currentIndex() >= 12) {
        format = "Mittelpunkt x,y,Größe";
        beispiel = "150,150,80";
    } else if (typ == "Rechteck" || typ == "Dreieck" || typ == "Raute" || typ == "Ellipse") {
        format = "x,y,Breite,Höhe";
        beispiel = "50,50,120,80";
    } else if (typ == "Trapez") {
        format = "x,y,obere Breite,untere Breite,Höhe";
        beispiel = "50,50,80,140,90";
    } else if (typ == "Parallelogramm") {
        format = "x,y,Breite,Höhe,Versatz";
        beispiel = "50,50,120,80,40";
    } else if (typ == "Kreissegment") {
        format = "Mittelpunkt x,y,Radius,Startgrad,Winkelgrad";
        beispiel = "150,150,80,0,90";
    } else if (typ == "Polygon") {
        format = "Mittelpunkt x,y,Radius,Ecken";
        beispiel = "150,150,80,7";
    } else if (typ == "Stern") {
        format = "Mittelpunkt x,y,Radius,Spitzen";
        beispiel = "150,150,80,5";
    } else if (typ == "Kreis" || typ == "Sechseck") {
        format = "Mittelpunkt x,y,Radius";
        beispiel = "150,150,80";
    } else {
        format = "x,y,Seite";
        beispiel = "50,50,100";
    }

    QString hilfe = "Eingabe: " + format + "   Beispiel: " + beispiel;
    if (typ == "Kreissegment")
        hilfe += "   0° = rechts, 90° = oben; negative Winkel drehen im Uhrzeigersinn.";
    ui->hilfeText->setText(hilfe);
    ui->eingabe->setPlaceholderText(beispiel);
}

void MainWindow::zeichnen()
{
    QString typ = ui->auswahl->currentText();
    QStringList teile = ui->eingabe->text().split(',');
    int anzahl = 3;
    if (typ == "Rechteck" || typ == "Dreieck" || typ == "Raute" || typ == "Ellipse" ||
        typ == "Polygon" || typ == "Stern")
        anzahl = 4;
    if (typ == "Trapez" || typ == "Parallelogramm" || typ == "Kreissegment")
        anzahl = 5;

    if (teile.size() != anzahl) {
        QMessageBox::warning(this, "Eingabe", "Bitte die Zahlen im angezeigten Format eingeben.");
        return;
    }

    int zahlen[5] = {0, 0, 0, 0, 0};
    for (int i = 0; i < anzahl; ++i) {
        bool ok;
        zahlen[i] = teile[i].trimmed().toInt(&ok);
        if (!ok) {
            QMessageBox::warning(this, "Eingabe", "Bitte nur ganze Zahlen eingeben.");
            return;
        }
    }

    int x = zahlen[0];
    int y = zahlen[1];
    int a = zahlen[2];
    int b = zahlen[3];
    int c = zahlen[4];
    bool gueltig = a > 0;
    if (typ == "Rechteck" || typ == "Dreieck" || typ == "Raute" ||
        typ == "Ellipse" || typ == "Trapez" || typ == "Parallelogramm")
        gueltig = gueltig && b > 0;
    if (typ == "Trapez")
        gueltig = gueltig && c > 0;
    if (typ == "Kreissegment")
        gueltig = gueltig && c != 0 && c >= -360 && c <= 360;
    if (typ == "Polygon")
        gueltig = gueltig && b >= 3 && b <= 100;
    if (typ == "Stern")
        gueltig = gueltig && b >= 3 && b <= 50;

    if (!gueltig) {
        QMessageBox::warning(this, "Eingabe", "Bitte positive Größen und gültige Ecken-, Spitzen- oder Winkelzahlen eingeben.");
        return;
    }

    Form *form = nullptr;
    if (typ == "Rechteck") form = new Rechteck(x, y, a, b);
    else if (typ == "Quadrat") form = new Quadrat(x, y, a);
    else if (typ == "Kreis") form = new Kreis(x, y, a);
    else if (typ == "Kreissegment") form = new Kreissegment(x, y, a, b, c);
    else if (typ == "Trapez") form = new Trapez(x, y, a, b, c);
    else if (typ == "Parallelogramm") form = new Parallelogramm(x, y, a, b, c);
    else if (typ == "Dreieck") form = new Dreieck(x, y, a, b);
    else if (typ == "Sechseck") form = new Sechseck(x, y, a);
    else if (typ == "Raute") form = new Raute(x, y, a, b);
    else if (typ == "Polygon") form = new RegelmaessigesPolygon(x, y, a, b);
    else if (typ == "Stern") form = new Stern(x, y, a, b);
    else if (typ == "Ellipse") form = new Ellipse(x, y, a, b);
    else if (ui->auswahl->currentIndex() >= 12 && ui->auswahl->currentIndex() < 18)
        form = zusatzformErstellen(ui->auswahl->currentIndex() - 12, x, y, a);
    else if (typ == "Halbkreis") form = new Halbkreis(x, y, a);
    else if (typ == "Viertelkreis") form = new Viertelkreis(x, y, a);
    else if (typ == "Ring") form = new Ring(x, y, a);
    else if (typ == "Fünfeck") form = new Fuenfeck(x, y, a);
    else if (typ == "Achteck") form = new Achteck(x, y, a);
    else if (typ == "Drachenviereck") form = new Drachenviereck(x, y, a);
    else if (typ == "Kreisbogen") form = new Kreisbogen(x, y, a);
    else if (typ == "Kreisabschnitt") form = new Kreisabschnitt(x, y, a);

    if (form)
        zeichenflaeche->formHinzufuegen(form);
}
