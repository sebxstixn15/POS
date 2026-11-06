#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "../tinyxml2/tinyxml2.h"

#include <QFile>
#include <QFileDialog>
#include <QDir>
#include <QMessageBox>
#include <QTreeWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    connect(ui->openButton, &QPushButton::clicked, this, &MainWindow::openXmlFile);
    connect(ui->folderButton, &QPushButton::clicked, this, &MainWindow::openFolder);
}

void MainWindow::openFolder()
{
    QString ordner = QFileDialog::getExistingDirectory(this, "Ordner auswählen");
    if (ordner.isEmpty())
        return;

    QDir verzeichnis(ordner);
    QStringList dateien = verzeichnis.entryList({"*.xml"}, QDir::Files, QDir::Name);
    ui->treeWidget->clear();
    if (dateien.isEmpty()) {
        QMessageBox::information(this, "Keine XML-Dateien", "In diesem Ordner gibt es keine XML-Dateien.");
        return;
    }

    for (const QString &datei : dateien) {
        QTreeWidgetItem *dateiEintrag = new QTreeWidgetItem(ui->treeWidget);
        dateiEintrag->setText(0, datei);

        tinyxml2::XMLDocument dokument;
        QString pfad = verzeichnis.filePath(datei);
        QByteArray dateiPfad = QFile::encodeName(pfad);
        if (dokument.LoadFile(dateiPfad.constData()) == tinyxml2::XML_SUCCESS) {
            addElement(dokument.RootElement(), dateiEintrag);
        } else {
            QTreeWidgetItem *fehler = new QTreeWidgetItem(dateiEintrag);
            fehler->setText(0, QString::fromUtf8(dokument.ErrorStr()));
        }
    }

    ui->treeWidget->expandAll();
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::openXmlFile()
{
    QString fileName = QFileDialog::getOpenFileName(
        this, "XML-Datei öffnen", "", "XML-Dateien (*.xml)");
    if (fileName.isEmpty())
        return;


    tinyxml2::XMLDocument document;
    QByteArray path = QFile::encodeName(fileName);
    if (document.LoadFile(path.constData()) != tinyxml2::XML_SUCCESS) {
        QMessageBox::warning(this, "Fehler", QString::fromUtf8(document.ErrorStr()));
        return;
    }

    ui->treeWidget->clear();
    addElement(document.RootElement(), nullptr);
    ui->treeWidget->expandAll();
}

void MainWindow::addElement(tinyxml2::XMLElement *element, QTreeWidgetItem *parent)
{
    if (element == nullptr)
        return;

    QTreeWidgetItem *item;
    if (parent == nullptr)
        item = new QTreeWidgetItem(ui->treeWidget);
    else
        item = new QTreeWidgetItem(parent);

    item->setText(0, element->Name());

    tinyxml2::XMLElement *child = element->FirstChildElement();
    while (child != nullptr) {
        addElement(child, item);
        child = child->NextSiblingElement();
    }
}
