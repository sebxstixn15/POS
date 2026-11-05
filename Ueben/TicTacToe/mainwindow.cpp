#include "mainwindow.h"
#include "./ui_mainwindow.h"
#include <QDialog>
#include <QVBoxLayout>
#include <QLabel>
#include <QPushButton>

bool gameStarted = false;

int player = 0;

QList<int> list;

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    static QIcon star(":/new/ressource/stern.png");
    static QIcon plus(":/new/ressource/plus.png");
    list = {0, 0, 0, 0, 0, 0, 0, 0, 0};

    QList<QPushButton*> buttons = {
        ui->btn1, ui->btn2, ui->btn3, ui->btn4, ui->btn5, ui->btn6, ui->btn7, ui->btn8, ui->btn9
    };

    for (QPushButton* btn : buttons) {
        connect(btn, &QPushButton::clicked, this, &MainWindow::onButtonClick);
    }
}



MainWindow::~MainWindow()
{
    delete ui;
}

void showPopup(QWidget *parent, QString text) {
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

int MainWindow::checkWin() {
    if (list[0] == list[1] && list[2] == list[0] && list[0] != 0
        || list[3] == list[4] && list[4] == list[5] && list[3] != 0
        || list[6] == list[7] && list[7] == list[8] && list[6] != 0
        || list[0] == list[3] && list[3] == list[6] && list[0] != 0
        || list[1] == list[4] && list[4] == list[7] && list[1] != 0
        || list[2] == list[5] && list[5] == list[8] && list[2] != 0
        || list[0] == list[4] && list[4] == list[8] && list[0] != 0
        || list[2] == list[4] && list[4] == list[6] && list[2] != 0) {


        showPopup(this, QString::fromStdString("Spieler " + std::to_string(player) + " gewinnt!"));
        gameStarted = false;
    }

}

void MainWindow::onButtonClick() {
    if (!gameStarted)
        return;

    QPushButton *gedrueckterButton = qobject_cast<QPushButton*>(sender());
    qDebug() << "Test: " << gedrueckterButton->objectName() << "Player: " << player;

    static QIcon star(":/new/ressource/stern.png");
    static QIcon plus(":/new/ressource/plus.png");

    std::string name = gedrueckterButton->objectName().toStdString();
    name.erase(0, 3);
    int btn = std::stoi(name);
    qDebug() << "int: " << btn;
    btn--;
    if (list[btn] != 0) return;

    if (player == 1) {
        list[btn] = player;
        gedrueckterButton->setIcon(star);

        checkWin();

        player = 2;
    } else {
        list[btn] = player;
        gedrueckterButton->setIcon(plus);

        checkWin();
        player = 1;
    }




}

void MainWindow::on_btnStart_clicked()
{
    if (gameStarted)
        return;
    gameStarted = true;
    srand((unsigned)time(0));

    player = (rand()%2)+1;
    std::string playerStart = "Spieler " + std::to_string(player) +  " beginnt";


    showPopup(this, QString::fromStdString(playerStart));
}

