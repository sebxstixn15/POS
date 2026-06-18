using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace Countdown
{
    /// <summary>
    /// Interaktionslogik für DateTimeDlg.xaml
    /// </summary>
    public partial class DateTimeDlg : Window
    {
        DateTime countDownTime;

        public DateTime CountDownTime
        {
            get { return countDownTime; }
            set
            {
                countDownTime = value;
                this.dtp.Value = countDownTime;
            }
        }

        public DateTimeDlg()
        {
            InitializeComponent();
        }

        private void buttonOkay_Click(object sender, RoutedEventArgs e)
        {
            if (dtp.Value != null)
            {
                countDownTime = (DateTime)this.dtp.Value;
                this.DialogResult = true;
                this.Close();
            }
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = false;
            this.Close();
        }
    }
}
