using System.Collections.ObjectModel;
using System.ComponentModel;

public enum FieldState { Empty, Player1, Player2 }

public class Field : INotifyPropertyChanged
{
    private FieldState _state = FieldState.Empty;
    public int X { get; set; }
    public int Y { get; set; }

    public FieldState State
    {
        get => _state;
        set
        {
            _state = value;
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(State)));
        }
    }
    public event PropertyChangedEventHandler PropertyChanged;
}

public class GameBoard
{
    public ObservableCollection<Field> Fields { get; } = new ObservableCollection<Field>();
    public int Size { get; }

    public GameBoard(int size)
    {
        Size = size;
        for (int i = 0; i < size * size; i++)
        {
            Fields.Add(new Field { X = i % size, Y = i / size });
        }
    }
}