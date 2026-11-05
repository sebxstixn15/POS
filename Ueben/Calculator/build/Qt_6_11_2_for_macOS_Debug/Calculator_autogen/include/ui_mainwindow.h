/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.11.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QWidget *gridLayoutWidget;
    QGridLayout *gridLayout;
    QPushButton *btn_solve;
    QPushButton *btn_minus;
    QPushButton *btnClear;
    QPushButton *btn_7;
    QPushButton *btn_div;
    QPushButton *btn_mal;
    QPushButton *btn_9;
    QPushButton *btn_4;
    QPushButton *btn_2;
    QPushButton *btn_1;
    QPushButton *btn_5;
    QPushButton *btn_8;
    QPushButton *btn_3;
    QPushButton *btn_0;
    QPushButton *btn_6;
    QPushButton *btn_plus;
    QVBoxLayout *verticalLayout;
    QLabel *label;
    QPushButton *btn_klammer_auf;
    QPushButton *btn_klammer_zu;
    QPushButton *btn_dec;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName("MainWindow");
        MainWindow->resize(800, 600);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName("centralwidget");
        gridLayoutWidget = new QWidget(centralwidget);
        gridLayoutWidget->setObjectName("gridLayoutWidget");
        gridLayoutWidget->setGeometry(QRect(220, 140, 461, 197));
        gridLayout = new QGridLayout(gridLayoutWidget);
        gridLayout->setObjectName("gridLayout");
        gridLayout->setContentsMargins(0, 0, 0, 0);
        btn_solve = new QPushButton(gridLayoutWidget);
        btn_solve->setObjectName("btn_solve");

        gridLayout->addWidget(btn_solve, 5, 3, 1, 1);

        btn_minus = new QPushButton(gridLayoutWidget);
        btn_minus->setObjectName("btn_minus");

        gridLayout->addWidget(btn_minus, 2, 3, 1, 1);

        btnClear = new QPushButton(gridLayoutWidget);
        btnClear->setObjectName("btnClear");

        gridLayout->addWidget(btnClear, 1, 0, 1, 1);

        btn_7 = new QPushButton(gridLayoutWidget);
        btn_7->setObjectName("btn_7");

        gridLayout->addWidget(btn_7, 4, 0, 1, 1);

        btn_div = new QPushButton(gridLayoutWidget);
        btn_div->setObjectName("btn_div");

        gridLayout->addWidget(btn_div, 4, 3, 1, 1);

        btn_mal = new QPushButton(gridLayoutWidget);
        btn_mal->setObjectName("btn_mal");

        gridLayout->addWidget(btn_mal, 3, 3, 1, 1);

        btn_9 = new QPushButton(gridLayoutWidget);
        btn_9->setObjectName("btn_9");

        gridLayout->addWidget(btn_9, 4, 2, 1, 1);

        btn_4 = new QPushButton(gridLayoutWidget);
        btn_4->setObjectName("btn_4");

        gridLayout->addWidget(btn_4, 3, 0, 1, 1);

        btn_2 = new QPushButton(gridLayoutWidget);
        btn_2->setObjectName("btn_2");

        gridLayout->addWidget(btn_2, 2, 1, 1, 1);

        btn_1 = new QPushButton(gridLayoutWidget);
        btn_1->setObjectName("btn_1");

        gridLayout->addWidget(btn_1, 2, 0, 1, 1);

        btn_5 = new QPushButton(gridLayoutWidget);
        btn_5->setObjectName("btn_5");

        gridLayout->addWidget(btn_5, 3, 1, 1, 1);

        btn_8 = new QPushButton(gridLayoutWidget);
        btn_8->setObjectName("btn_8");

        gridLayout->addWidget(btn_8, 4, 1, 1, 1);

        btn_3 = new QPushButton(gridLayoutWidget);
        btn_3->setObjectName("btn_3");

        gridLayout->addWidget(btn_3, 2, 2, 1, 1);

        btn_0 = new QPushButton(gridLayoutWidget);
        btn_0->setObjectName("btn_0");

        gridLayout->addWidget(btn_0, 5, 1, 1, 1);

        btn_6 = new QPushButton(gridLayoutWidget);
        btn_6->setObjectName("btn_6");

        gridLayout->addWidget(btn_6, 3, 2, 1, 1);

        btn_plus = new QPushButton(gridLayoutWidget);
        btn_plus->setObjectName("btn_plus");

        gridLayout->addWidget(btn_plus, 1, 3, 1, 1);

        verticalLayout = new QVBoxLayout();
        verticalLayout->setObjectName("verticalLayout");
        label = new QLabel(gridLayoutWidget);
        label->setObjectName("label");

        verticalLayout->addWidget(label);


        gridLayout->addLayout(verticalLayout, 0, 0, 1, 4);

        btn_klammer_auf = new QPushButton(gridLayoutWidget);
        btn_klammer_auf->setObjectName("btn_klammer_auf");

        gridLayout->addWidget(btn_klammer_auf, 1, 1, 1, 1);

        btn_klammer_zu = new QPushButton(gridLayoutWidget);
        btn_klammer_zu->setObjectName("btn_klammer_zu");

        gridLayout->addWidget(btn_klammer_zu, 1, 2, 1, 1);

        btn_dec = new QPushButton(gridLayoutWidget);
        btn_dec->setObjectName("btn_dec");

        gridLayout->addWidget(btn_dec, 5, 2, 1, 1);

        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName("menubar");
        menubar->setGeometry(QRect(0, 0, 800, 30));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName("statusbar");
        MainWindow->setStatusBar(statusbar);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "MainWindow", nullptr));
        btn_solve->setText(QCoreApplication::translate("MainWindow", "Solve", nullptr));
        btn_minus->setText(QCoreApplication::translate("MainWindow", "-", nullptr));
        btnClear->setText(QCoreApplication::translate("MainWindow", "C", nullptr));
        btn_7->setText(QCoreApplication::translate("MainWindow", "7", nullptr));
        btn_div->setText(QCoreApplication::translate("MainWindow", "/", nullptr));
        btn_mal->setText(QCoreApplication::translate("MainWindow", "*", nullptr));
        btn_9->setText(QCoreApplication::translate("MainWindow", "9", nullptr));
        btn_4->setText(QCoreApplication::translate("MainWindow", "4", nullptr));
        btn_2->setText(QCoreApplication::translate("MainWindow", "2", nullptr));
        btn_1->setText(QCoreApplication::translate("MainWindow", "1", nullptr));
        btn_5->setText(QCoreApplication::translate("MainWindow", "5", nullptr));
        btn_8->setText(QCoreApplication::translate("MainWindow", "8", nullptr));
        btn_3->setText(QCoreApplication::translate("MainWindow", "3", nullptr));
        btn_0->setText(QCoreApplication::translate("MainWindow", "0", nullptr));
        btn_6->setText(QCoreApplication::translate("MainWindow", "6", nullptr));
        btn_plus->setText(QCoreApplication::translate("MainWindow", "+", nullptr));
        label->setText(QString());
        btn_klammer_auf->setText(QCoreApplication::translate("MainWindow", "(", nullptr));
        btn_klammer_zu->setText(QCoreApplication::translate("MainWindow", ")", nullptr));
        btn_dec->setText(QCoreApplication::translate("MainWindow", ",", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
