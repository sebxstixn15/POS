#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QDialog>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>


bool gamestate = false;

int player = 0;


MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}


void MainWindow::onButtonClick(){

}

void MainWindow::on_btn_start_clicked()
{
    if (gamestate) return;

    gamestate = true;

    srand((unsigned)time(0));

    player = (rand()%2)+1;

    showPopup(this, QString::fromStdString("Spieler " + std::to_string(player) + " gewinnt!"));

}



void MainWindow::showPopup(QWidget *parent, QString text) {
    QDialog popup(parent);
    popup.setWindowTitle("Popup Dialog");
    popup.resize(300, 150);

    QVBoxLayout *layout = new QVBoxLayout(&popup);
    QLabel *label = new QLabel(text, &popup);
    QPushButton *btn = new QPushButton("Schließen", &popup);

    layout->addWidget(label);
    layout->addWidget(btn);

    // Verbinde den Button mit dem Schließen-Slot
    QObject::connect(btn, &QPushButton::clicked, &popup, &QDialog::accept);

    // Öffnet den Dialog modal (blockiert das Hauptfenster)
    popup.exec();
}

