using System.ComponentModel;
using System.Diagnostics;
using System.Resources;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace RatingControl
{
    /// <summary>
    /// Follow steps 1a or 1b and then 2 to use this custom control in a XAML file.
    ///
    /// Step 1a) Using this custom control in a XAML file that exists in the current project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:RatingControl"
    ///
    ///
    /// Step 1b) Using this custom control in a XAML file that exists in a different project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:RatingControl;assembly=RatingControl"
    ///
    /// You will also need to add a project reference from the project where the XAML file lives
    /// to this project and Rebuild to avoid compilation errors:
    ///
    ///     Right click on the target project in the Solution Explorer and
    ///     "Add Reference"->"Projects"->[Select this project]
    ///
    ///
    /// Step 2)
    /// Go ahead and use your control in the XAML file.
    ///
    ///     <MyNamespace:CustomControl1/>
    ///
    /// </summary>
    public class RatingControl : Control
    {
        static RatingControl()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(RatingControl), new FrameworkPropertyMetadata(typeof(RatingControl)));
        }

        TextBlock _rating;
        Image pic1;
        Image pic2;
        Image pic3;
        Image pic4;
        Image pic5;
        Image star_selected;
        Image star_unselected;

        public override void OnApplyTemplate()
        {
            base.OnApplyTemplate();
            _rating = GetTemplateChild("ratingTextBlock") as TextBlock;
            pic1 = GetTemplateChild("pic1") as Image;
            pic2 = GetTemplateChild("pic2") as Image;
            pic3 = GetTemplateChild("pic3") as Image;
            pic4 = GetTemplateChild("pic4") as Image;
            pic5 = GetTemplateChild("pic5") as Image;
            star_selected = GetTemplateChild("star_selected") as Image;
            star_unselected = GetTemplateChild("star_unselected") as Image;


            pic1.MouseLeftButtonDown += changeRating1;
            pic2.MouseLeftButtonDown += changeRating2;
            pic3.MouseLeftButtonDown += changeRating3;
            pic4.MouseLeftButtonDown += changeRating4;
            pic5.MouseLeftButtonDown += changeRating5;


        }

        public void changeRating1(object sender, RoutedEventArgs e)
        {
            Rating = 1;
        }

        public void changeRating2(object sender, RoutedEventArgs e)
        {
            Rating = 2;
        }

        public void changeRating3(object sender, RoutedEventArgs e)
        {
            Rating = 3;
        }

        public void changeRating4(object sender, RoutedEventArgs e)
        {
            Rating = 4;
        }

        public void changeRating5(object sender, RoutedEventArgs e)
        {
            Rating = 5;
        }

        public static readonly DependencyProperty RatingProperty =
         DependencyProperty.Register("Rating", typeof(int), typeof(RatingControl),
           new PropertyMetadata(1, OnRatingChanged));

        
        public int Rating
        {
            get => (int)GetValue(RatingProperty);
            set => SetValue(RatingProperty, value);
        }
        private static void OnRatingChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is RatingControl ctrl)
            {
                int neuerWert = (int)e.NewValue;
                Debug.WriteLine($"Rating geändert auf: {neuerWert}");
                ctrl.changeStars(neuerWert);
                
            }
        }

        public static readonly DependencyProperty ShowNumberProperty =
         DependencyProperty.Register("ShowNumber", typeof(Visibility), typeof(RatingControl),
           new PropertyMetadata(Visibility.Visible, OnShowNumberChanged));
        public Visibility ShowNumber
        {
            get => (Visibility)GetValue(ShowNumberProperty);
            set => SetValue(ShowNumberProperty, value);
        }

        
        private static void OnShowNumberChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is RatingControl ctrl)
            {
                Visibility neuerWert = (Visibility)e.NewValue;
                Debug.WriteLine($"ShowNumber geändert auf: {neuerWert}");
                ctrl.changeRating(neuerWert);
            }
        }
        public void changeRating(Visibility visibility)
        {
            _rating.Visibility = visibility;
        }

        public void changeStars(int number)
        {
            switch (number)
            {
                case 1:
                    pic1.Source = star_selected.Source;
                    pic2.Source = star_unselected.Source;
                    pic3.Source = star_unselected.Source;
                    pic4.Source = star_unselected.Source;
                    pic5.Source = star_unselected.Source; ;
                    break;
                case 2:
                    pic1.Source = star_selected.Source;
                    pic2.Source = star_selected.Source;
                    pic3.Source = star_unselected.Source;
                    pic4.Source = star_unselected.Source;
                    pic5.Source = star_unselected.Source; ;
                    break;
                case 3:
                    pic1.Source = star_selected.Source;
                    pic2.Source = star_selected.Source;
                    pic3.Source = star_selected.Source;
                    pic4.Source = star_unselected.Source;
                    pic5.Source = star_unselected.Source; ;
                    break;
                case 4:
                    pic1.Source = star_selected.Source;
                    pic2.Source = star_selected.Source;
                    pic3.Source = star_selected.Source;
                    pic4.Source = star_selected.Source;
                    pic5.Source = star_unselected.Source; ;
                    break;
                case 5:
                    pic1.Source = star_selected.Source;
                    pic2.Source = star_selected.Source;
                    pic3.Source = star_selected.Source;
                    pic4.Source = star_selected.Source;
                    pic5.Source = star_selected.Source; ;
                    break;
            }

        }

    }
}