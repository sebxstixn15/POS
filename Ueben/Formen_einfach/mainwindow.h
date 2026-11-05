#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QList>
#include "formen.h"

class Zeichenflaeche : public QWidget
{
public:
    explicit Zeichenflaeche(QWidget *parent = nullptr);
    ~Zeichenflaeche() override;
    void formHinzufuegen(Form *form);

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QList<Form *> formen;
};

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private:
    void zeichnen();
    void hilfeAktualisieren();

    Ui::MainWindow *ui;
    Zeichenflaeche *zeichenflaeche;
};

#endif
