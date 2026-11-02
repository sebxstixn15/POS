#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "tinyxml2.h"

#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QMessageBox>
#include <QStatusBar>
#include <QTreeWidget>

namespace {
constexpr int ElementPointerRole = Qt::UserRole;
}

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent),
      ui_(std::make_unique<Ui::MainWindow>()),
      document_(std::make_unique<tinyxml2::XMLDocument>())
{
    ui_->setupUi(this);

    connect(ui_->openButton, &QPushButton::clicked, this, &MainWindow::openXmlFile);
    connect(ui_->treeWidget, &QTreeWidget::itemSelectionChanged,
            this, &MainWindow::selectionChanged);
}

MainWindow::~MainWindow() = default;

void MainWindow::openXmlFile()
{
    const QString fileName = QFileDialog::getOpenFileName(
        this, tr("XML-Datei auswählen"), QString(), tr("XML-Dateien (*.xml);;Alle Dateien (*)"));
    if (fileName.isEmpty())
        return;

    auto newDocument = std::make_unique<tinyxml2::XMLDocument>();
    const QByteArray nativeName = QFile::encodeName(fileName);
    const tinyxml2::XMLError result = newDocument->LoadFile(nativeName.constData());
    if (result != tinyxml2::XML_SUCCESS) {
        QMessageBox::critical(this, tr("XML konnte nicht geöffnet werden"),
                              QString::fromUtf8(newDocument->ErrorStr()));
        return;
    }

    ui_->treeWidget->clear();
    document_ = std::move(newDocument);

    for (auto *element = document_->FirstChildElement(); element;
         element = element->NextSiblingElement()) {
        addElement(element, nullptr);
    }
    ui_->treeWidget->expandToDepth(1);
    ui_->treeWidget->resizeColumnToContents(0);
    ui_->fileLabel->setText(QFileInfo(fileName).fileName());
    ui_->fileLabel->setToolTip(fileName);
    statusBar()->showMessage(tr("XML-Datei erfolgreich geladen"), 3000);
}

void MainWindow::addElement(tinyxml2::XMLElement *element, QTreeWidgetItem *parent)
{
    auto *item = parent ? new QTreeWidgetItem(parent) : new QTreeWidgetItem(ui_->treeWidget);
    item->setText(0, QString::fromUtf8(element->Name()));
    const char *text = element->GetText();
    if (text)
        item->setText(1, QString::fromUtf8(text).trimmed().left(80));
    item->setData(0, ElementPointerRole,
                  QVariant::fromValue<qulonglong>(reinterpret_cast<qulonglong>(element)));

    for (auto *child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {
        addElement(child, item);
    }
}

tinyxml2::XMLElement *MainWindow::selectedElement() const
{
    const auto items = ui_->treeWidget->selectedItems();
    if (items.isEmpty())
        return nullptr;
    return reinterpret_cast<tinyxml2::XMLElement *>(
        items.first()->data(0, ElementPointerRole).toULongLong());
}

void MainWindow::selectionChanged()
{
    showElementDetails(selectedElement());
}

void MainWindow::showElementDetails(tinyxml2::XMLElement *element)
{
    if (!element) {
        ui_->detailsTextEdit->clear();
        return;
    }

    QStringList lines;
    lines << tr("Element: <%1>").arg(QString::fromUtf8(element->Name())) << QString();
    lines << tr("Attribute:");
    for (const tinyxml2::XMLAttribute *attribute = element->FirstAttribute(); attribute;
         attribute = attribute->Next()) {
        const QString name = QString::fromUtf8(attribute->Name());
        const QString value = QString::fromUtf8(attribute->Value());
        lines << QStringLiteral("  %1 = \"%2\"").arg(name, value);
    }
    if (!element->FirstAttribute())
        lines << tr("  (keine)");

    lines << QString() << tr("Inhalt:");
    const char *text = element->GetText();
    lines << (text ? QString::fromUtf8(text).trimmed() : tr("  (kein Textinhalt)"));
    ui_->detailsTextEdit->setPlainText(lines.join('\n'));
}
