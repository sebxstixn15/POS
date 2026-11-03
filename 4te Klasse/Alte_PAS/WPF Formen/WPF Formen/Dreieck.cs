using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace WPF_Formen
{
    // Dreieck (Gleichschenklig innerhalb des Rechtecks X1,Y1 bis X2,Y2)
    internal class Dreieck : Rechteck
    {
        protected override PathFigure CreatePathFigure()
        {
            PathFigure figure = new PathFigure { StartPoint = new Point((X1 + X2) / 2, Y1), IsClosed = true };
            figure.Segments.Add(new LineSegment(new Point(X2, Y2), true));
            figure.Segments.Add(new LineSegment(new Point(X1, Y2), true));
            return figure;
        }
    }

    // Ellipse
   
}
