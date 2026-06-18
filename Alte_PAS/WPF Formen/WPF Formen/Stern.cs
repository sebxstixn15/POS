using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media;
using System.Windows;

namespace WPF_Formen
{
    internal class Stern : Basis
    {
        public int Zacken { get; set; } = 5;
        public double RadiusAussen { get; set; } = 50;
        public double RadiusInnen { get; set; } = 20;

        protected override PathFigure CreatePathFigure()
        {
            PathFigure figure = new PathFigure();
            int punkte = Zacken * 2;
            for (int i = 0; i < punkte; i++)
            {
                double r = (i % 2 == 0) ? RadiusAussen : RadiusInnen;
                double angle = 2 * Math.PI * i / punkte - Math.PI / 2;
                Point p = new Point(X1 + r * Math.Cos(angle), Y1 + r * Math.Sin(angle));
                if (i == 0) figure.StartPoint = p;
                else figure.Segments.Add(new LineSegment(p, true));
            }
            figure.IsClosed = true;
            return figure;
        }
    }
}
