using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.CompilerServices;
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
    public class Login : Control

    {
        static Login()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(Login), new FrameworkPropertyMetadata(typeof(Login)));
        }

        private Button _loginButton;
        private Button _switch;
        private PasswordBox _passwordbox;
        public override void OnApplyTemplate()
        {
            base.OnApplyTemplate();

            _loginButton = GetTemplateChild("LOGIN_Button") as Button;
            _switch = GetTemplateChild("PART_LOGIN") as Button;
            _passwordbox = GetTemplateChild("PART_PASSWORD") as PasswordBox;


            if (_loginButton != null)
            {
                _loginButton.Click += LoginButton_Click;
            }
            if (_switch != null)
            {
                _switch.Click += _switch_Click;
            }
        }

        public static readonly RoutedEvent SwitchToRegistrationEvent =
    EventManager.RegisterRoutedEvent("SwitchToRegistration", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(Login));

        public event RoutedEventHandler SwitchToRegistration
        {
            add => AddHandler(SwitchToRegistrationEvent, value);
            remove => RemoveHandler(SwitchToRegistrationEvent, value);
        }

        private void _switch_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SwitchToRegistrationEvent));
        }

        public static readonly DependencyProperty EMailProperty =
         DependencyProperty.Register("Email", typeof(string), typeof(Login),
           new PropertyMetadata(string.Empty, OnEmailChanged));
        public string Email
        {
            get => (string)GetValue(EMailProperty);
            set => SetValue(EMailProperty, value);
        }
        private static void OnEmailChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            if (d is Login ctrl)
            {
                string neuerWert = (string)e.NewValue;
                Debug.WriteLine($"Email geändert auf: {neuerWert}");
            }
        }

        

        public void LoginButton_Click(object sender, RoutedEventArgs e)
        {
            string Passwort = _passwordbox?.Password ?? string.Empty;
            Debug.WriteLine(Email + ", " + Passwort);
            return;
        }
    }
}