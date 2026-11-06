#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "rechner.h"

#include <QLineEdit>
#include <QMessageBox>
#include <QPushButton>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    connect(ui->berechnenButton, &QPushButton::clicked,
            this, &MainWindow::berechnen);
    connect(ui->eingabe, &QLineEdit::returnPressed,
            this, &MainWindow::berechnen);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::berechnen()
{
    double ergebnis;
    QString fehler;

    if (!berechneUPN(ui->eingabe->text(), ergebnis, fehler)) {
        ui->ergebnis->setText("Ergebnis: –");
        QMessageBox::warning(this, "Fehler", fehler);
        return;
    }

    ui->ergebnis->setText("Ergebnis: " + QString::number(ergebnis, 'g', 15));
}
