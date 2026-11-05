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
#include <QtWidgets/QComboBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
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
    QVBoxLayout *verticalLayout;
    QHBoxLayout *eingabeLayout;
    QComboBox *auswahl;
    QLineEdit *eingabe;
    QPushButton *zeichnenButton;
    QLabel *hilfeText;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName("MainWindow");
        MainWindow->resize(800, 600);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName("centralwidget");
        verticalLayout = new QVBoxLayout(centralwidget);
        verticalLayout->setObjectName("verticalLayout");
        eingabeLayout = new QHBoxLayout();
        eingabeLayout->setObjectName("eingabeLayout");
        auswahl = new QComboBox(centralwidget);
        auswahl->addItem(QString());
        auswahl->addItem(QString());
        auswahl->setObjectName("auswahl");

        eingabeLayout->addWidget(auswahl);

        eingabe = new QLineEdit(centralwidget);
        eingabe->setObjectName("eingabe");

        eingabeLayout->addWidget(eingabe);

        zeichnenButton = new QPushButton(centralwidget);
        zeichnenButton->setObjectName("zeichnenButton");

        eingabeLayout->addWidget(zeichnenButton);


        verticalLayout->addLayout(eingabeLayout);

        hilfeText = new QLabel(centralwidget);
        hilfeText->setObjectName("hilfeText");
        hilfeText->setWordWrap(true);

        verticalLayout->addWidget(hilfeText);

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
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "Formen einfach zeichnen", nullptr));
        auswahl->setItemText(0, QCoreApplication::translate("MainWindow", "Kreis", nullptr));
        auswahl->setItemText(1, QCoreApplication::translate("MainWindow", "Quadrat", nullptr));

        eingabe->setPlaceholderText(QCoreApplication::translate("MainWindow", "x,y,Gr\303\266\303\237e (z. B. 100,100,40)", nullptr));
        zeichnenButton->setText(QCoreApplication::translate("MainWindow", "Zeichnen", nullptr));
        hilfeText->setText(QCoreApplication::translate("MainWindow", "Eingabe:", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
