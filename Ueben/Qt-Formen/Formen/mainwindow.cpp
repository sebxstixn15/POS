#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <iostream>
#include "factory.h"
#include <QDir>
#include <QLibrary>
#include <QCoreApplication>

using namespace std;

DrawingArea::DrawingArea(QWidget *parent) : QWidget(parent)
{
    setAutoFillBackground(true);
}

void DrawingArea::addForm(Form *form)
{
    forms.append(form);
    update();
}

void DrawingArea::paintEvent(QPaintEvent *event)
{
    QWidget::paintEvent(event);
    QPainter painter(this);
    for (Form *form : forms)
        form->draw(painter);
}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    connect(ui->pushButton, &QPushButton::clicked,
            this, &MainWindow::on_pushButton_clicked);
    connect(ui->form_select, &QComboBox::currentTextChanged,
            this, &MainWindow::on_form_select_currentTextChanged);
    drawingArea = new DrawingArea(ui->centralWidget);
    drawingArea->setGeometry(0, 0, 320, 390);
    drawingArea->show();
    factory = new Factory();

    load_plugins();
    //ui->form_select->insertItems(0, Factory::instance()->getFormList());
}

void MainWindow::load_plugins()
{
    cout << "Loading Plugins ..." << endl;
    cout << "Current Directory " << QDir::currentPath().toStdString() << endl;
    QDir directory(QCoreApplication::applicationDirPath() + "/plugins");
    QStringList plugins = directory.entryList(
        QStringList() << "*.dll" << "*.DLL" << "*.dylib" << "*.so", QDir::Files);
    foreach(QString filename, plugins) {
        cout << filename.toStdString() << endl;
        QLibrary library(directory.filePath(filename));
        library.setLoadHints(QLibrary::PreventUnloadHint);
            if (!library.load())
            {
                qDebug() << library.errorString();
            }
            else
            {
                qDebug() << "library loaded";
            }

            typedef bool (*RegisterFormFunction)(Factory *);
            RegisterFormFunction rff = (RegisterFormFunction)library.resolve("registerForm");
            if (!rff || !rff(factory)) {
                qDebug() << "Could not show widget from the loaded library";
            }
    }

    ui->form_select->insertItems(0, factory->getFormList());
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_pushButton_clicked()
{
    Form *f = factory->createForm(ui->form_select->currentText(), ui->data_input->text());
    if(f)
    {
        drawingArea->addForm(f);
    }
}

void MainWindow::on_form_select_currentTextChanged(const QString &arg1)
{
    ui->help_text->setText(factory->getHelpText(arg1));
}


