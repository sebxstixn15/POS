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
    internal class Quadrat : Basis
    {
        public static readonly DependencyProperty aProperty = DependencyProperty.Register("a", typeof(Double), typeof(Rechteck), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));
        

        [TypeConverter(typeof(LengthConverter))]
        public double a
        {
            get { return (double)base.GetValue(aProperty); }
            set { base.SetValue(aProperty, value); }
        }



        /// <summary>
        /// Zeichnet ein Rechteck
        /// </summary>
        protected override PathFigure CreatePathFigure()
        {
            PathFigure myPathFigure = new PathFigure();
            myPathFigure.StartPoint = new Point(X1, Y1);
            myPathFigure.Segments.Add(new LineSegment(new Point(X1+a, Y1), true));
            myPathFigure.Segments.Add(new LineSegment(new Point(X1 + a, Y1+a), true));
            myPathFigure.Segments.Add(new LineSegment(new Point(X1, Y1 + a), true));
            myPathFigure.IsClosed = true;
            return myPathFigure;
        }
    }
}
