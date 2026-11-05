#pragma once

#include <QHash>
#include <QMainWindow>
#include <QString>
#include <tinyxml2.h>

class QTreeWidgetItem;

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void openXmlFile();
    void elementSelected();
    void attributeSelected();
    void changeAttribute();
    void saveXmlFile();

private:
    void addElement(tinyxml2::XMLElement *element, QTreeWidgetItem *parent);

    Ui::MainWindow *ui;
    tinyxml2::XMLDocument document;
    QHash<QTreeWidgetItem *, tinyxml2::XMLElement *> elements;
    QString currentFile;
    bool changed = false;
};
