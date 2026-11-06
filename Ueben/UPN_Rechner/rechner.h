#ifndef RECHNER_H
#define RECHNER_H

#include <QString>

// Gibt true bei Erfolg zurück. Bei Fehler steht die Ursache in fehler.
bool berechneUPN(const QString &ausdruck, double &ergebnis, QString &fehler);

#endif
