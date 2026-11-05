#include "mainwindow.h"
#include "./ui_mainwindow.h"
#include "math_d.h"




MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    QList<QPushButton*> buttons = {
        ui->btn_0, ui->btn_1, ui->btn_2, ui->btn_3, ui->btn_4,
        ui->btn_5, ui->btn_6, ui->btn_7, ui->btn_8, ui->btn_9,
        ui->btn_div, ui->btn_mal, ui->btn_minus, ui->btn_plus,
        ui->btn_klammer_auf, ui->btn_klammer_zu, ui->btn_dec
    };

    for (QPushButton* btn : buttons) {
        connect(btn, &QPushButton::clicked, this, &MainWindow::onButtonClick);
    }
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_btnClear_clicked()
{
    ui->label->clear();
}

void MainWindow::onButtonClick(){
    QPushButton *gedrueckterButton = qobject_cast<QPushButton*>(sender());

    if (ui->label->text() == "Error") ui->label->clear();
    ui->label->setText(ui->label->text() + gedrueckterButton->text());
}


void MainWindow::on_btn_solve_clicked()
{
    ui->label->setText(QString::number(Math_D::calculate(ui->label->text())));
}

