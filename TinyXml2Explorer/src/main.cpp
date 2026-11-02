#include "mainwindow.h"

#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setApplicationName("TinyXML2 Explorer");
    QApplication::setOrganizationName("Qt Schulprojekt");

    MainWindow window;
    window.show();
    return app.exec();
}
