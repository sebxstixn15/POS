using Painter;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace PainterApp
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private Regex regex = new Regex(@"COLOR|FOR|DRAW|TURN|\d+|{|}|\S+");
        private Regex stringRegex = new Regex(@"\w+");
        private Regex numberRegex = new Regex(@"\d+");
        private Regex keywordRegex = new Regex(@"COLOR|FOR|DRAW|TURN");

        private List<Token> tokens = new List<Token>();

        public MainWindow()
        {
            InitializeComponent();

           
            PainterCanvas.Clear();

            Code.Text = "";
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            // 1. Schritt: Tokenisieren
            PainterCanvas.Clear();
            tokens.Clear();
            foreach (Match match in regex.Matches(Code.Text))
            {
                Token token = new Token() { Value = match.Value };
                tokens.Add(token);
                switch (match.Value)
                {
                    

                    case var _ when numberRegex.IsMatch(match.Value):
                        token.Type = Token.TokenType.Number;
                        break;

                    case var _ when keywordRegex.IsMatch(match.Value):
                        token.Type = Token.TokenType.Keyword;
                        break;

                    case var _ when stringRegex.IsMatch(match.Value):
                        token.Type = Token.TokenType.String;
                        break;

                    case "{":
                        token.Type = Token.TokenType.OpenBracket;
                        break;

                    case "}":
                        token.Type = Token.TokenType.CloseBracket;
                        break;
                }
            }
            TokensList.ItemsSource = tokens;

            //Schritt 1.5: Fehlerhafte Tokens ausgeben
            var errors = tokens.Where(t => t.Type == Token.TokenType.Error).ToList();
            if (errors.Count > 0)
            {
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("Fehlerhafte Tokens:");
                foreach (var error in errors)
                {
                    sb.AppendLine(error.Value);
                }
                MessageBox.Show(sb.ToString(), "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }

            //Schritt 2: Parsen
            Programm programm = new();
            programm.Parse(tokens);

            //Schritt 2.5: Fehlerhafte Anweisungen ausgeben
            if (Expression.Errors.Count > 0)
            {
                StringBuilder builder = new StringBuilder();
                builder.AppendLine("Fehlerhafte Anweisungen:");
                foreach (var error in Expression.Errors)
                {
                    builder.AppendLine(error);
                }
                MessageBox.Show(builder.ToString(), "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            Expression.Errors.Clear();

            ThreadPool.QueueUserWorkItem(_ =>
            {
                // Schritt 3: Ausführen
                programm.Run(PainterCanvas);

                //Schritt 3.5: Fehlerhafte Ausführung ausgeben
                if (Expression.Errors.Count > 0)
                {
                    StringBuilder builder = new StringBuilder();
                    builder.AppendLine("Fehlerhafte Ausführung:");
                    foreach (var error in Expression.Errors)
                    {
                        builder.AppendLine(error);
                    }
                    MessageBox.Show(builder.ToString(), "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
                }
                Expression.Errors.Clear();
            });


        }
    }
}