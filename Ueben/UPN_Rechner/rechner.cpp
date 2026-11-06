#include "rechner.h"

#include <QStack>
#include <QStringList>
#include <cmath>

bool berechneUPN(const QString &ausdruck, double &ergebnis, QString &fehler)
{
    QStack<double> stack;
    QStringList teile = ausdruck.split(' ', Qt::SkipEmptyParts);

    if (teile.isEmpty()) {
        fehler = "Bitte einen Ausdruck eingeben.";
        return false;
    }

    for (const QString &teil : teile) {
        bool istZahl;
        double zahl = teil.toDouble(&istZahl);

        if (istZahl) {
            if (!std::isfinite(zahl)) {
                fehler = "Die Zahl ist zu groß.";
                return false;
            }
            stack.push(zahl);
            continue;
        }

        if (teil != "+" && teil != "-" && teil != "*" && teil != "/") {
            fehler = "Unbekanntes Zeichen: " + teil;
            return false;
        }

        if (stack.size() < 2) {
            fehler = "Für den Operator " + teil + " fehlen Zahlen.";
            return false;
        }

        double rechts = stack.pop();
        double links = stack.pop();
        double wert = 0;

        if (teil == "+") wert = links + rechts;
        if (teil == "-") wert = links - rechts;
        if (teil == "*") wert = links * rechts;
        if (teil == "/") {
            if (rechts == 0) {
                fehler = "Division durch 0 ist nicht erlaubt.";
                return false;
            }
            wert = links / rechts;
        }

        if (!std::isfinite(wert)) {
            fehler = "Das Ergebnis ist zu groß.";
            return false;
        }
        stack.push(wert);
    }

    if (stack.size() != 1) {
        fehler = "Der Ausdruck enthält zu viele Zahlen.";
        return false;
    }

    ergebnis = stack.pop();
    return true;
}
