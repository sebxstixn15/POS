using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Media;

namespace WPF_Formen
{
    class Kreis_Radius : Quadrat
    {
        // Standardmäßig ein voller Kreis
        private double _winkel = 45;

        public double Radius
        {
            get { return a / 2; }
            set { a = value * 2; }
        }

        /// <summary>
        /// Der Winkel des Kreissektors in Grad (0 bis 360).
        /// </summary>
        public double Winkel
        {
            get { return _winkel; }
            set { _winkel = value; }
        }

        protected override PathFigure CreatePathFigure()
        {
            double r = Radius;
            PathFigure myPathFigure = new PathFigure();

            // Fall 1: Voller Kreis (360 Grad oder mehr) - Alte Logik (stabilste Methode für volle Kreise)
            if (Winkel >= 360)
            {
                myPathFigure.StartPoint = new Point(X1 + r, Y1); // Start Oben

                // Erster Halbkreis
                myPathFigure.Segments.Add(new ArcSegment(
                    new Point(X1 + r, Y1 + 2 * r),
                    new Size(r, r),
                    0, false, SweepDirection.Clockwise, true));

                // Zweiter Halbkreis zurück zum Start
                myPathFigure.Segments.Add(new ArcSegment(
                    new Point(X1 + r, Y1),
                    new Size(r, r),
                    0, false, SweepDirection.Clockwise, true));
            }
            // Fall 2: Tortenstück (Weniger als 360 Grad)
            else
            {
                // Mittelpunkt des Kreises berechnen
                Point center = new Point(X1 + r, Y1 + r);

                // Wir starten im Mittelpunkt (für das "Tortenstück"-Aussehen)
                myPathFigure.StartPoint = center;

                // 1. Linie vom Mittelpunkt senkrecht nach Oben (zum Start des Bogens)
                Point arcStart = new Point(X1 + r, Y1);
                myPathFigure.Segments.Add(new LineSegment(arcStart, true));

                // 2. Endpunkt des Bogens berechnen
                // Umrechnung von Grad in Radiant: (Winkel * PI) / 180
                double angleRad = (Winkel * Math.PI) / 180.0;

                // Berechnung der Koordinaten (Start ist Oben/12 Uhr, daher Sin/Cos angepasst)
                // X = Mx + r * sin(α)
                // Y = My - r * cos(α)
                double endX = center.X + r * Math.Sin(angleRad);
                double endY = center.Y - r * Math.Cos(angleRad);
                Point arcEnd = new Point(endX, endY);

                // Wichtig: Ist der Bogen größer als 180 Grad?
                bool isLargeArc = Winkel > 180.0;

                // 3. Den Bogen zeichnen
                myPathFigure.Segments.Add(new ArcSegment(
                    arcEnd,                     // Zielpunkt
                    new Size(r, r),             // Radius x, Radius y
                    0,                          // Drehung (hier egal)
                    isLargeArc,                 // Groß (über 180°) oder klein?
                    SweepDirection.Clockwise,   // Uhrzeigersinn
                    true));
            }

            myPathFigure.IsClosed = true; // Verbindet Endpunkt automatisch wieder mit Startpunkt (Mittelpunkt)
            return myPathFigure;
        }
    }
}