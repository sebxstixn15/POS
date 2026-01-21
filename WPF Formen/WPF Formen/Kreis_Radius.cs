using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Media;

namespace WPF_Formen
{
    class Kreis : Quadrat
    {
        /// <summary>
        /// Gibt den Radius zurück oder setzt ihn.
        /// Setzt intern 'a' (Durchmesser) auf Radius * 2.
        /// </summary>
        public double Radius
        {
            get { return a / 2; }
            set { a = value * 2; }
        }

        /// <summary>
        /// Zeichnet einen Kreis basierend auf dem Radius
        /// </summary>
        protected override PathFigure CreatePathFigure()
        {
            // Wir holen uns den Radius in eine lokale Variable für bessere Lesbarkeit
            double r = Radius;

            PathFigure myPathFigure = new PathFigure();
            
            // Startpunkt: Oben in der Mitte des "Quadrats" (X1 + r, Y1)
            myPathFigure.StartPoint = new Point(X1 + r, Y1);

            // 1. Halbkreis (von Oben nach Unten)
            // Zielpunkt: X1 + r, Y1 + 2*r (was Y1 + a entspricht)
            myPathFigure.Segments.Add(new ArcSegment(
                new Point(X1 + r, Y1 + 2 * r), 
                new Size(r, r), 
                0, 
                false, 
                SweepDirection.Clockwise, 
                true));

            // 2. Halbkreis (von Unten zurück nach Oben)
            // Zielpunkt: Wieder der Startpunkt
            myPathFigure.Segments.Add(new ArcSegment(
                new Point(X1 + r, Y1), 
                new Size(r, r), 
                0, 
                false, 
                SweepDirection.Clockwise, 
                true));

            myPathFigure.IsClosed = true;
            return myPathFigure;
        }
    }
}