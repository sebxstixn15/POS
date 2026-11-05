#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "../tinyxml2/tinyxml2.h"

#include <QFile>
#include <QFileDialog>
#include <QMessageBox>
#include <QTreeWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    connect(ui->openButton, &QPushButton::clicked, this, &MainWindow::openXmlFile);
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
