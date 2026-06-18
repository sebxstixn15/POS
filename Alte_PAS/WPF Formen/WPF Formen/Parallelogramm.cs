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

    // Parallelogramm
    internal class Parallelogramm : Rechteck
    {
        protected override PathFigure CreatePathFigure()
        {
            double offset = 20;
            PathFigure figure = new PathFigure { StartPoint = new Point(X1 + offset, Y1), IsClosed = true };
            figure.Segments.Add(new LineSegment(new Point(X2, Y1), true));
            figure.Segments.Add(new LineSegment(new Point(X2 - offset, Y2), true));
            figure.Segments.Add(new LineSegment(new Point(X1, Y2), true));
            return figure;
        }
    }
}
