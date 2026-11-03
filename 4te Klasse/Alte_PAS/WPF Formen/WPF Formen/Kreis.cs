using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace WPF_Formen
{
    class Kreis : Quadrat
    {

        /// <summary>
        /// Zeichnet ein Rechteck
        /// </summary>
        protected override PathFigure CreatePathFigure()
        {
            PathFigure myPathFigure = new PathFigure();
            myPathFigure.StartPoint = new Point(X1 + a/2, Y1);
            myPathFigure.Segments.Add(new ArcSegment(new Point(X1 + a/2, Y1+ a), new Size(a/2, a/2), 0, false, SweepDirection.Clockwise, true));
            myPathFigure.Segments.Add(new ArcSegment(new Point(X1 + a / 2, Y1), new Size(a / 2, a / 2), 0, false, SweepDirection.Clockwise, true));
            myPathFigure.IsClosed = true;
            return myPathFigure;
        }
    }
}
