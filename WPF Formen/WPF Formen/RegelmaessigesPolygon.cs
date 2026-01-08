using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using System.Windows;

namespace WPF_Formen
{
    internal class RegelmaessigesPolygon : Basis
    {
        public int Ecken { get; set; } = 6; // Standard Sechseck
        public double Radius { get; set; } = 50;

        protected override PathFigure CreatePathFigure()
        {
            PathFigure figure = new PathFigure();
            for (int i = 0; i < Ecken; i++)
            {
                double angle = 2 * Math.PI * i / Ecken - Math.PI / 2;
                Point p = new Point(X1 + Radius * Math.Cos(angle), Y1 + Radius * Math.Sin(angle));
                if (i == 0) figure.StartPoint = p;
                else figure.Segments.Add(new LineSegment(p, true));
            }
            figure.IsClosed = true;
            return figure;
        }
    }
}
