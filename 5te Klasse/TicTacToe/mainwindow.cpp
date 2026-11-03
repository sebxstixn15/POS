#include "mainwindow.h"
#include "./ui_mainwindow.h"


QString star_file = ":/new/prefix1/star.png";
QString sketch_file = ":/new/prefix1/sketch.png";

const QIcon *star;
const QIcon *sketch;
QList<QString*> list;

bool gamestate;

QString* one;
QString* two;


MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , player(1)

{
    ui->setupUi(this);




    star = new QIcon(star_file);
    sketch = new QIcon(sketch_file);

    one = new QString("1");
    two = new QString("2");

    list = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr};

    gamestate = true;

}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::action(QPushButton *button, int number) {
    if (gamestate) {
        if (player == 1) {
            if (list[number] == nullptr) {
                list[number] = one;
                button->setIcon(*star);
                player = 2;
            }

        } else {
            if (list[number] == nullptr) {
                list[number] = two;
                button->setIcon(*sketch);
                player = 1;
            }

        }

        if (list[0] == list[1] && list[2] == list[0] && list[0] != nullptr
            || list[3] == list[4] && list[4] == list[5] && list[3] != nullptr
            || list[6] == list[7] && list[7] == list[8] && list[6] != nullptr
            || list[0] == list[3] && list[3] == list[6] && list[0] != nullptr
            || list[1] == list[4] && list[4] == list[7] && list[1] != nullptr
            || list[2] == list[5] && list[5] == list[8] && list[2] != nullptr
            || list[0] == list[4] && list[4] == list[8] && list[0] != nullptr
            || list[2] == list[4] && list[4] == list[6] && list[2] != nullptr) {


            qDebug() << __FILE__ << __LINE__ << "Player has won";
            gamestate = false;
        }
        qDebug() << __FILE__ << __LINE__ << list;
    }

}

void MainWindow::on_pushButton_clicked()
{
    action(ui->pushButton, 0);



}
void MainWindow::on_pushButton_2_clicked()
{
    action(ui->pushButton_2, 1);
}


void MainWindow::on_pushButton_3_clicked()
{
    action(ui->pushButton_3, 2);
}


void MainWindow::on_pushButton_6_clicked()
{
    action(ui->pushButton_6, 5);
}


void MainWindow::on_pushButton_5_clicked()
{
    action(ui->pushButton_5, 4);
}


void MainWindow::on_pushButton_4_clicked()
{
    action(ui->pushButton_4, 3);
}


void MainWindow::on_pushButton_9_clicked()
{
    action(ui->pushButton_9, 8);
}


void MainWindow::on_pushButton_8_clicked()
{
    action(ui->pushButton_8, 7);
}


void MainWindow::on_pushButton_7_clicked()
{
    action(ui->pushButton_7, 6);
}


