using System.ComponentModel;
using System.Diagnostics;
using System.Media;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;

namespace Countdown
{
    /// <summary>
    /// Follow steps 1a or 1b and then 2 to use this custom control in a XAML file.
    ///
    /// Step 1a) Using this custom control in a XAML file that exists in the current project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:Countdown"
    ///
    ///
    /// Step 1b) Using this custom control in a XAML file that exists in a different project.
    /// Add this XmlNamespace attribute to the root element of the markup file where it is 
    /// to be used:
    ///
    ///     xmlns:MyNamespace="clr-namespace:Countdown;assembly=Countdown"
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
    public class Countdown : Control, INotifyPropertyChanged
    {
        static double countdownseconds = 0;
        static double countdownminutes = 0;
        static Countdown()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(Countdown), new FrameworkPropertyMetadata(typeof(Countdown)));
        }

       

        public static readonly DependencyProperty
            CountdownTimeProperty = DependencyProperty.Register(
                    "CountdownTime",
                  typeof(DateTime),
                     typeof(Countdown),
            new FrameworkPropertyMetadata(
               DateTime.Now, null));



        public DateTime CountdownTime
        {
            get { return (DateTime)base.GetValue(CountdownTimeProperty); }
            set { base.SetValue(CountdownTimeProperty, value); 
            }
        }


        
        public static readonly DependencyProperty CountdownTimerVisualProperty =
            DependencyProperty.Register(
            "CountdownTimerVisual",
            typeof(DateTime),
            typeof(Countdown),
            new FrameworkPropertyMetadata(DateTime.MinValue, FrameworkPropertyMetadataOptions.BindsTwoWayByDefault));

        public DateTime CountdownTimerVisual
        {
            get => (DateTime)GetValue(CountdownTimerVisualProperty);
            set => SetValue(CountdownTimerVisualProperty, value);
        }
        public DateTime CountdownTimer;


        public static readonly DependencyProperty
        AlarmSetProperty = DependencyProperty.Register(
                "AlarmSet",
                typeof(bool),
                    typeof(Countdown),
        new FrameworkPropertyMetadata(
            false,
            FrameworkPropertyMetadataOptions.BindsTwoWayByDefault));


        public bool AlarmSet
        {
            get { return (bool)base.GetValue(AlarmSetProperty); }
            set { base.SetValue(AlarmSetProperty, value); }
        }

        public static readonly DependencyProperty
            CurrentTimeProperty = DependencyProperty.Register(
                    "CurrentTime",
                  typeof(DateTime),
                     typeof(Countdown),
            new FrameworkPropertyMetadata(
               DateTime.Now, null));


        public DateTime CurrentTime
        {
            get { return (DateTime)base.GetValue(CurrentTimeProperty); }
            set { base.SetValue(CurrentTimeProperty, value); }
        }


        public static readonly RoutedEvent AlarmEvent =
           EventManager.RegisterRoutedEvent("Alarm",
             RoutingStrategy.Bubble, typeof(RoutedEventHandler),
             typeof(Countdown));


        public event RoutedEventHandler Alarm
        {
            add { base.AddHandler(AlarmEvent, value); }
            remove { base.RemoveHandler(AlarmEvent, value); }
        }


        protected void FireAlarm()
        {
            base.RaiseEvent(new RoutedEventArgs(AlarmEvent));
        }


        protected void RingAlarm()
        {
            SoundPlayer sp = new SoundPlayer(@"c:\windows\media\tada.wav");
            sp.Play();
            FireAlarm();
        }
        private bool _isRunning = false;
        public void OnDisplayTimerTick(object o, EventArgs args)
        {
            this.CurrentTime = DateTime.Now;

            if (this.AlarmSet)
            {
                if (!_isRunning)
                {
                    this.CountdownTime = DateTime.Now
                        .AddMinutes(this.CountdownTimer.Minute)
                        .AddSeconds(this.CountdownTimer.Second);
                    _isRunning = true;
                }

                long remainingTicks = this.CountdownTime.Ticks - DateTime.Now.Ticks;

                if (remainingTicks > 0)
                {
                    this.CountdownTimerVisual = new DateTime(remainingTicks);
                }
                else
                {
                    this.CountdownTimerVisual = new DateTime(CountdownTimer.Ticks);
                    this.AlarmSet = false;
                    _isRunning = false; 
                    RingAlarm();
                }
            }
            else
            {
                if (_isRunning == true || this.CountdownTimerVisual.Ticks == 0)
                {
                    this.CountdownTimerVisual = this.CountdownTimer;
                    _isRunning = false;
                }
            }
        }


        void OnShowSetAlarmDlg(object sender, RoutedEventArgs ea)
        {
            DateTimeDlg dateTimeDlg = new DateTimeDlg();
            dateTimeDlg.CountDownTime = this.CountdownTimer;

            if (dateTimeDlg.ShowDialog() == true)
            {
                this.CountdownTimer = dateTimeDlg.CountDownTime;

                this.CountdownTimerVisual = dateTimeDlg.CountDownTime;

                this.AlarmSet = false;
                _isRunning = false;

                Debug.WriteLine(this.CountdownTimer.Minute + " " + this.CountdownTimer.Second);
            }
        }


        System.Windows.Threading.DispatcherTimer displayTimer;

        public override void OnApplyTemplate()
        {
            base.OnApplyTemplate();

            Button bSetAlarmDlg =
                (Button)this.Template.FindName("PART_SETALARMBUTTON", this);

            bSetAlarmDlg.Click += OnShowSetAlarmDlg;

            displayTimer = new System.Windows.Threading.DispatcherTimer();
            displayTimer.Interval = new TimeSpan(0, 0, 0, 0, 250);
            displayTimer.Tick += OnDisplayTimerTick;

            displayTimer.Start();

            CheckBox cbAlarmSet = (CheckBox)this.Template.FindName("PART_CHECKBOXALARMSET", this);
            Binding bindingAlarmSet = new Binding();
            bindingAlarmSet.Source = this;
            bindingAlarmSet.Path = new PropertyPath("AlarmSet");
            cbAlarmSet.SetBinding(CheckBox.IsCheckedProperty, bindingAlarmSet);


            TextBlock tbCurrentTime =
                (TextBlock)this.Template.FindName("PART_CURRENTDATETIME", this);
            Binding bindingCurrentTime = new Binding();
            bindingCurrentTime.Source = this;
            bindingCurrentTime.Path = new PropertyPath("CurrentTime");
            tbCurrentTime.SetBinding(TextBlock.TextProperty, bindingCurrentTime);
        }


        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) =>
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
     
}