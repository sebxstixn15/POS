using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;

namespace WPF_Formen
{
    internal class EllipseForm : Rechteck
    {
        protected override Geometry DefiningGeometry
        {
            get => new EllipseGeometry(new Rect(new Point(X1, Y1), new Point(X2, Y2)));
        }
    }
}
