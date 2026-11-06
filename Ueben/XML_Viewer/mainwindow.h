#pragma once

#include <QMainWindow>

class QTreeWidgetItem;

namespace tinyxml2 {
class XMLElement;
}

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
    void openFolder();

private:
    void addElement(tinyxml2::XMLElement *element, QTreeWidgetItem *parent);

    Ui::MainWindow *ui;
};
