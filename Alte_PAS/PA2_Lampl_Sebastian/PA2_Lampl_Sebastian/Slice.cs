using PA2_4B_2026;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace PA2_Lampl_Sebastian
{
    internal class Slice : PA2_4B_2026.Basis
    {
        public static readonly DependencyProperty RadiusProperty = DependencyProperty.Register("Radius", typeof(Double), typeof(Slice), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));
        public static readonly DependencyProperty AngleProperty = DependencyProperty.Register("Angle", typeof(Double), typeof(Slice), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));
        
        [TypeConverter(typeof(LengthConverter))]
        public double Radius
        {
            get { return (double)base.GetValue(RadiusProperty); }
            set { base.SetValue(RadiusProperty, value); }
        }

        [TypeConverter(typeof(LengthConverter))]
        public double Angle
        {
            get { return (double)base.GetValue(AngleProperty); }
            set { base.SetValue(AngleProperty, value); }
        }
        protected override PathFigure CreatePathFigure()
        {
            PathFigure myPathFigure = new PathFigure();
            myPathFigure.StartPoint = new Point(X1 + Radius / 2, Y1);
            myPathFigure.Segments.Add(new ArcSegment(new Point(X1 + Radius / 2, Y1 + Radius), new Size(Radius / 2, Radius / 2), 0, false, SweepDirection.Counterclockwise, true));
     
            myPathFigure.IsClosed = true;
            return myPathFigure;
        }
    }
}
