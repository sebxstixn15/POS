#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QList>
#include "form.h"
#include "factory.h"

class DrawingArea : public QWidget
{
public:
    explicit DrawingArea(QWidget *parent = nullptr);
    void addForm(Form *form);

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QList<Form *> forms;
};

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:
    void on_pushButton_clicked();
    void on_form_select_currentTextChanged(const QString &arg1);

    Ui::MainWindow *ui;
    DrawingArea *drawingArea;
    Factory *factory;
    void load_plugins();
};

#endif // MAINWINDOW_H
