#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QFile>
#include <QFileDialog>
#include <QMessageBox>
#include <QTreeWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    connect(ui->openButton, &QPushButton::clicked, this, &MainWindow::openXmlFile);
    connect(ui->treeWidget, &QTreeWidget::itemSelectionChanged,
            this, &MainWindow::elementSelected);
    connect(ui->attributeBox, &QComboBox::currentIndexChanged,
            this, &MainWindow::attributeSelected);
    connect(ui->changeButton, &QPushButton::clicked, this, &MainWindow::changeAttribute);
    connect(ui->saveButton, &QPushButton::clicked, this, &MainWindow::saveXmlFile);
    ui->saveButton->setEnabled(false);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::openXmlFile()
{
    if (changed) {
        QMessageBox::StandardButton answer = QMessageBox::question(
            this, "Ungespeicherte Änderungen", "Änderungen verwerfen und andere Datei öffnen?",
            QMessageBox::Yes | QMessageBox::No);
        if (answer != QMessageBox::Yes)
            return;
    }

    QString fileName = QFileDialog::getOpenFileName(
        this, "XML-Datei öffnen", "", "XML-Dateien (*.xml)");
    if (fileName.isEmpty())
        return;

    tinyxml2::XMLDocument newDocument;
    QByteArray path = QFile::encodeName(fileName);
    if (newDocument.LoadFile(path.constData()) != tinyxml2::XML_SUCCESS) {
        QMessageBox::warning(this, "Fehler", QString::fromUtf8(newDocument.ErrorStr()));
        return;
    }

    ui->treeWidget->clear();
    elements.clear();
    document.Clear();
    document.DeepCopy(&newDocument);
    currentFile = fileName;
    changed = false;
    ui->saveButton->setEnabled(false);
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
    elements[item] = element;

    tinyxml2::XMLElement *child = element->FirstChildElement();
    while (child != nullptr) {
        addElement(child, item);
        child = child->NextSiblingElement();
    }
}

void MainWindow::elementSelected()
{
    ui->attributeBox->clear();
    ui->valueEdit->clear();

    QTreeWidgetItem *item = ui->treeWidget->currentItem();
    if (item == nullptr)
        return;

    tinyxml2::XMLElement *element = elements.value(item);
    if (element == nullptr)
        return;

    const tinyxml2::XMLAttribute *attribute = element->FirstAttribute();
    while (attribute != nullptr) {
        ui->attributeBox->addItem(attribute->Name());
        attribute = attribute->Next();
    }
    attributeSelected();
}

void MainWindow::attributeSelected()
{
    ui->valueEdit->clear();
    QTreeWidgetItem *item = ui->treeWidget->currentItem();
    if (item == nullptr || ui->attributeBox->currentText().isEmpty())
        return;

    tinyxml2::XMLElement *element = elements.value(item);
    QByteArray name = ui->attributeBox->currentText().toUtf8();
    const char *value = element->Attribute(name.constData());
    if (value != nullptr)
        ui->valueEdit->setText(QString::fromUtf8(value));
}

void MainWindow::changeAttribute()
{
    QTreeWidgetItem *item = ui->treeWidget->currentItem();
    if (item == nullptr || ui->attributeBox->currentText().isEmpty())
        return;

    tinyxml2::XMLElement *element = elements.value(item);
    QByteArray name = ui->attributeBox->currentText().toUtf8();
    QByteArray value = ui->valueEdit->text().toUtf8();
    element->SetAttribute(name.constData(), value.constData());
    changed = true;
    ui->saveButton->setEnabled(true);
}

void MainWindow::saveXmlFile()
{
    QByteArray path = QFile::encodeName(currentFile);
    if (document.SaveFile(path.constData()) != tinyxml2::XML_SUCCESS) {
        QMessageBox::warning(this, "Fehler", "Die XML-Datei konnte nicht gespeichert werden.");
        return;
    }
    changed = false;
    ui->saveButton->setEnabled(false);
    QMessageBox::information(this, "Gespeichert", "Die XML-Datei wurde gespeichert.");
}
