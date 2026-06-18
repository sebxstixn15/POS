using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using System.Windows;

namespace WPF_Formen
{
    // Trapez (X1,Y1 oben links; X2,Y2 unten rechts)
    internal class Trapez : Rechteck
    {
        protected override PathFigure CreatePathFigure()
        {
            double offset = (X2 - X1) * 0.2; // 20% Einrückung für Trapezform
            PathFigure figure = new PathFigure { StartPoint = new Point(X1 + offset, Y1), IsClosed = true };
            figure.Segments.Add(new LineSegment(new Point(X2 - offset, Y1), true));
            figure.Segments.Add(new LineSegment(new Point(X2, Y2), true));
            figure.Segments.Add(new LineSegment(new Point(X1, Y2), true));
            return figure;
        }
    }
}
