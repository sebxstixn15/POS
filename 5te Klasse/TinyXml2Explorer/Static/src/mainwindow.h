#pragma once

#include <QMainWindow>
#include <memory>

class QTreeWidgetItem;

namespace tinyxml2 {
class XMLDocument;
class XMLElement;
}

namespace Ui {
class MainWindow;
}

class MainWindow final : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private slots:
    void openXmlFile();
    void selectionChanged();

private:
    void addElement(tinyxml2::XMLElement *element, QTreeWidgetItem *parent);
    tinyxml2::XMLElement *selectedElement() const;
    void showElementDetails(tinyxml2::XMLElement *element);

    std::unique_ptr<Ui::MainWindow> ui_;
    std::unique_ptr<tinyxml2::XMLDocument> document_;
};
