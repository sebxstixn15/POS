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
    internal class Spirale : Basis
    {
        public static readonly DependencyProperty SteigungProperty = DependencyProperty.Register("Steigung", typeof(Double), typeof(Spirale), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));
        public static readonly DependencyProperty UmdrehungenProperty = DependencyProperty.Register("Umdrehungen", typeof(Double), typeof(Spirale), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));

        [TypeConverter(typeof(LengthConverter))]
        public double Steigung
        {
            get { return (double)base.GetValue(SteigungProperty); }
            set { base.SetValue(SteigungProperty, value); }
        }

        [TypeConverter(typeof(LengthConverter))]
        public double Umdrehungen
        {
            get { return (double)base.GetValue(UmdrehungenProperty); }
            set { base.SetValue(UmdrehungenProperty, value); }
        }

        public static readonly DependencyProperty EckenProperty = DependencyProperty.Register("Ecken", typeof(Double), typeof(Slice), new FrameworkPropertyMetadata(0.0, FrameworkPropertyMetadataOptions.AffectsRender | FrameworkPropertyMetadataOptions.AffectsMeasure));
        
       

        [TypeConverter(typeof(LengthConverter))]
        public double Ecken
        {
            get { return (double)base.GetValue(EckenProperty); }
            set { base.SetValue(EckenProperty, value); }
        }
        public double Radius { get; set; } = 50;



        protected override PathFigure CreatePathFigure()
        {
            PathFigure figure = new PathFigure();
            for (int i = 0; i < Umdrehungen; i++)
            {
                for (int i2 = 0; i2 < Ecken; i2++)
                {
                    double angle = 2 * Math.PI * i2 / Ecken - Math.PI / 2;
                    Point p = new Point(X1 + Radius * Math.Cos(angle), Y1 + Radius * Math.Sin(angle));
                    if (i2 == 0) figure.StartPoint = p;
                    else figure.Segments.Add(new LineSegment(p, true));
                }
            }
                
            figure.IsClosed = true;
            return figure;
        }
    }
}
