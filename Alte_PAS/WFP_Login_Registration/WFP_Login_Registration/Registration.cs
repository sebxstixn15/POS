using Microsoft.Win32;
using System.Diagnostics;
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

namespace WFP_Login_Registration
{
    /// <summary>
    /// Follow steps 1a or 1b and then 2 to use this custom control in a XAML file.
    ///
    /// Step 1a) Using this custom control in a XAML file that exists in the current project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:WFP_Login_Registration"
    ///
    ///
    /// Step 1b) Using this custom control in a XAML file that exists in a different project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:WFP_Login_Registration;assembly=WFP_Login_Registration"
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
    public class Registration : Control
    {
        static Registration()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(Registration), new FrameworkPropertyMetadata(typeof(Registration)));
        }

        private Button _submitButton;
        private Button _resetButton;
        private Button _cancelButton;
        private Button _switch;
        private PasswordBox _passwordbox;
        private PasswordBox _passwordbox_confirm;
        public override void OnApplyTemplate()
        {
            base.OnApplyTemplate();

            _submitButton = GetTemplateChild("SUBMIT_Button") as Button;
            _resetButton = GetTemplateChild("RESET_Button") as Button;
            _cancelButton = GetTemplateChild("CANCEL_Button") as Button;
            _switch = GetTemplateChild("PART_LOGIN") as Button;
            _passwordbox = GetTemplateChild("PART_PASSWORD") as PasswordBox;
            _passwordbox_confirm = GetTemplateChild("PART_PASSWORD_CONFIRM") as PasswordBox;

            _submitButton.Click += SubmitButton_Click;
            _resetButton.Click += ResetButton_Click;
            _cancelButton.Click += CanceltButton_Click;
            _switch.Click += _switch_Click;
        }




        private void CanceltButton_Click(object sender, RoutedEventArgs e)
        {
            Debug.WriteLine("Cancel");
        }

        private void ResetButton_Click(object sender, RoutedEventArgs e)
        {
            Debug.WriteLine("Reset");
        }

        public static readonly RoutedEvent SwitchToLoginEvent =
            EventManager.RegisterRoutedEvent("SwitchToLogin", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(Registration));

        public event RoutedEventHandler SwitchToLogin
        {
            add => AddHandler(SwitchToLoginEvent, value);
            remove => RemoveHandler(SwitchToLoginEvent, value);
        }

        private void _switch_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SwitchToLoginEvent));
        }

        public static readonly DependencyProperty EMailProperty =
         DependencyProperty.Register("Email", typeof(string), typeof(Registration),
           new PropertyMetadata(string.Empty, OnEmailChanged));
        public string Email
        {
            get => (string)GetValue(EMailProperty);
            set => SetValue(EMailProperty, value);
        }
        private static void OnEmailChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is Registration ctrl)
            {
                string neuerWert = (string)e.NewValue;
                Debug.WriteLine($"Email geändert auf: {neuerWert}");
            }
        }

        public static readonly DependencyProperty FirstProperty =
         DependencyProperty.Register("First", typeof(string), typeof(Registration),
           new PropertyMetadata(string.Empty, OnFirstChanged));
        public string First
        {
            get => (string)GetValue(FirstProperty);
            set => SetValue(FirstProperty, value);
        }
        private static void OnFirstChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is Registration ctrl)
            {
                string neuerWert = (string)e.NewValue;
                Debug.WriteLine($"First geändert auf: {neuerWert}");
            }
        }

        public static readonly DependencyProperty LastProperty =
         DependencyProperty.Register("Last", typeof(string), typeof(Registration),
           new PropertyMetadata(string.Empty, OnLastChanged));
        public string Last
        {
            get => (string)GetValue(LastProperty);
            set => SetValue(LastProperty, value);
        }
        private static void OnLastChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is Registration ctrl)
            {
                string neuerWert = (string)e.NewValue;
                Debug.WriteLine($"Last geändert auf: {neuerWert}");
            }
        }



        private void SubmitButton_Click(object sender, RoutedEventArgs e)
        {
            Debug.WriteLine("Submit");
            string Passwort = _passwordbox?.Password ?? string.Empty;
            string Passwort2 = _passwordbox_confirm?.Password ?? string.Empty;
            Debug.WriteLine(Email + ", " + Passwort + ", " + Passwort2 + ", " + First + ", " + Last);
            return;
        }
    }
}