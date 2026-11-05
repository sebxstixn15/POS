#include "mainwindow.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setApplicationName("XML Viewer Statisch");
    QApplication::setOrganizationName("Qt Schulprojekt");

    MainWindow window;
    window.show();
    return app.exec();
}
