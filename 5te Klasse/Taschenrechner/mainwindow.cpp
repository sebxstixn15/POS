#include "mainwindow.h"
#include "./ui_mainwindow.h"
#include <cmath>
#include "math_d.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    QList<QPushButton*> buttons = {
        ui->zero, ui->one, ui->two, ui->three, ui->four,
        ui->five, ui->six, ui->seven, ui->eight, ui->nine,
        ui->modulo,
        ui->divide, ui->mal, ui->minus, ui->plus,
        ui->klammer_auf, ui->klammer_zu
    };

    for (QPushButton* btn : buttons) {
        connect(btn, &QPushButton::clicked, this, &MainWindow::onButtonClick);
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::onButtonClick()
{
    // Herausfinden, wer das Signal gesendet hat:
    QPushButton *gedrueckterButton = qobject_cast<QPushButton*>(sender());

    if (gedrueckterButton) {
        if (ui->label->text() == "Error") {
            ui->label->clear();
        }
        QString text = gedrueckterButton->text();
        ui->label->setText(ui->label->text() + text);
    }
}

void MainWindow::on_delete_2_clicked()
{
    QString text = ui->label->text();
    if (text == "Error") {
        ui->label->clear();
    } else if (!text.isEmpty()) {
        text.chop(1);
        ui->label->setText(text);
    }
}

void MainWindow::on_clear_clicked()
{
    ui->label->clear();
}

void MainWindow::on_solve_clicked()
{
    QString term = ui->label->text();
    if (term.isEmpty()) {
        return;
    }

    double result = Math_D::calculate(term);

    if (std::isnan(result)) {
        ui->label->setText("Error");
    } else {
        ui->label->setText(QString::number(result));
    }
}

