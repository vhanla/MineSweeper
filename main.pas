unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

const
  GridSize = 12; // 1:1
  MineCount = 15;

type
  TCellData = class
  public
    X: Integer;
    Y: Integer;
    constructor Create(AX, AY: Integer);
  end;

  TForm1 = class(TForm)
    GridPanelLayout1: TGridPanelLayout;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    Cells: array of array of TRectangle;
    Mines, Revealed, Flags: array of array of Boolean;
    GameActive, MinesPlaced: Boolean;
    procedure InitializeGrid;
    procedure PlaceMines(ExcludeX, ExcludeY: Integer);
    procedure RevealCell(X, Y: Integer);
    function CountAdjacentMines(X, Y: Integer): Integer;
    procedure UpdateCell(X, Y: Integer);
    procedure GameOver(Won: Boolean);
    procedure ResetGame(Sender: TObject);
    procedure CellClick(Sender: TObject);
    procedure CellMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    function CheckWin:Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  ResetGame(nil)
end;

procedure TForm1.CellClick(Sender: TObject);
var
  Data: TCellData;
  X, Y: Integer;
begin
  if not GameActive then Exit;

  Data := TCellData((Sender as TRectangle).TagObject);
  X := Data.X;
  Y := Data.Y;

  if not MinesPlaced then
  begin
    PlaceMines(X, Y);
    MinesPlaced := True;
  end;

  if Flags[X][Y] then Exit;

  if Mines[X][Y] then
  begin
    GameOver(False);
    Exit;
  end;

  RevealCell(X, Y);
  if CheckWin then GameOver(True);
end;

procedure TForm1.CellMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  Data: TCellData;
  XCell, YCell: Integer;
begin
  if Button <> TMouseButton.mbRight  then Exit;

  Data := TCellData((Sender as TRectangle).TagObject);
  XCell := Data.X;
  YCell := Data.Y;

  if not Revealed[XCell][YCell] then
  begin
    Flags[XCell][YCell] := not Flags[XCell][YCell];
    UpdateCell(XCell, YCell);
  end;
end;

function TForm1.CheckWin: Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i := 0 to GridSize - 1 do
    for j := 0 to GridSize -1 do
      begin
        if not Mines[i][j] and not Revealed[i][j] then
        begin
          Result := False;
          Exit;
        end;

      end;

end;

function TForm1.CountAdjacentMines(X, Y: Integer): Integer;
var
  dx, dy, nx, ny: Integer;
begin
  Result := 0;
  for dx := -1 to 1 do
    for dy := -1 to 1 do
      begin
        if (dx = 0) and (dy = 0) then Continue;

        nx := X + dx;
        ny := Y + dy;

        if (nx >= 0) and (nx < GridSize) and
           (ny >= 0) and (ny < GridSize) then
        begin
          if Mines[nx][ny] then
            Inc(Result);
        end;
      end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitializeGrid;
  ResetGame(nil);
  Caption := 'MineSweeper';
  Button1.Text := 'New Game';
end;

procedure TForm1.GameOver(Won: Boolean);
var
  i, j: Integer;
begin
  GameActive := False;

  for I := 0 to GridSize - 1 do
    for J := 0 to GridSize - 1 do
      begin
        if Mines[i][j] then
        begin
          Revealed[i][j] := True;
          UpdateCell(i, j);
        end;
      end;

  if Won then
    ShowMessage('You won!')
  else
    ShowMessage('Game Over!');
end;

procedure TForm1.InitializeGrid;
var
  i, j: Integer;
  Cell: TRectangle;
  lLabel: TLabel;
begin
  GridPanelLayout1.DeleteChildren;
  GridPanelLayout1.RowCollection.Clear;
  GridPanelLayout1.ColumnCollection.Clear;

// Set up grid dimensions
  GridPanelLayout1.BeginUpdate;
  try
    // Create rows
    for i := 1 to GridSize do
      with GridPanelLayout1.RowCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
        //Value := 100 / GridSize;
      end;

    // Create columns
    for i := 1 to GridSize do
      with GridPanelLayout1.ColumnCollection.Add do
      begin
        SizeStyle := TGridPanelLayout.TSizeStyle.Auto;
        //Value := 100 / GridSize;
      end;
  finally
    GridPanelLayout1.EndUpdate;
  end;

  // Initialize arrays
  SetLength(Cells, GridSize, GridSize);
  SetLength(Mines, GridSize, GridSize);
  SetLength(Revealed, GridSize, GridSize);
  SetLength(Flags, GridSize, GridSize);

  // Create cells
  for i := 0 to GridSize-1 do
    for j := 0 to GridSize-1 do
    begin
      Cell := TRectangle.Create(GridPanelLayout1);
      Cells[i][j] := Cell;
      Cell.Parent := GridPanelLayout1;

      // Visual setup
      Cell.Align := TAlignLayout.Client;
      Cell.Margins.Rect := TRectF.Create(1, 1, 1, 1);
      Cell.Stroke.Kind := TBrushKind.None;
      Cell.Fill.Color := TAlphaColorRec.Lightgray;
      Cell.TagObject := TCellData.Create(i, j);
      Cell.OnClick := CellClick;
      Cell.OnMouseDown := CellMouseDown;

      lLabel := TLabel.Create(Cell);
      lLabel.Parent := Cell;
      lLabel.Align := TAlignLayout.Client;
      lLabel.TextSettings.HorzAlign := TTextAlign.Center;
      lLabel.TextSettings.VertAlign := TTextAlign.Center;
      lLabel.Visible := False;
    end;
end;

procedure TForm1.PlaceMines(ExcludeX, ExcludeY: Integer);
var
  Placed, X, Y: Integer;
begin
  Randomize;
  Placed := 0;
  while Placed < MineCount do
  begin
    X := Random(GridSize);
    Y := Random(GridSize);
    if (X = ExcludeX) and (Y = ExcludeY) then Continue;
    if not Mines[X][Y] then
    begin
      Mines[X][Y] := True;
      Inc(Placed);
    end;
  end;
end;

procedure TForm1.ResetGame(Sender: TObject);
var
  i, j: Integer;
begin
  GameActive := True;
  MinesPlaced := False;

  for I := 0 to GridSize - 1 do
    for J := 0 to GridSize - 1 do
      begin
        Mines[i][j] := False;
        Revealed[i][j] := False;
        Flags[i][j] := False;
        UpdateCell(i, j);
      end;
end;

procedure TForm1.RevealCell(X, Y: Integer);
var
  dx, dy, nx, ny: Integer;
begin
  if Revealed[X][Y] or Flags[X][Y] then Exit;

  Revealed[X][Y] := True;
  UpdateCell(X, Y);

  if CountAdjacentMines(X, Y) = 0 then
  begin
    for dx := -1 to 1 do
      for dy := -1 to 1 do
        begin
          nx := X + dx;
          ny := Y + dy;
          if (nx >= 0) and (nx < GridSize) and (ny >= 0) and (ny < GridSize) then
            RevealCell(nx, ny);
        end;
  end;
end;

procedure TForm1.UpdateCell(X, Y: Integer);
var
  Cell: TRectangle;
  lLabel: TLabel;
  Count: Integer;
begin
  Cell := Cells[X][Y];
  lLabel := TLabel(Cell.Children[0]);

  if Revealed[X][Y] then
  begin
    Cell.Fill.Color := TAlphaColorRec.White;
    lLabel.Visible := True;

    if Mines[X][Y] then
    begin
      lLabel.Text := '💣';
    end
    else
    begin
      Count := CountAdjacentMines(X, Y);
      case Count of
        0: lLabel.Visible := False;
        1: lLabel.TextSettings.FontColor := TAlphaColorRec.Blue;
        2: lLabel.TextSettings.FontColor := TAlphaColorRec.Green;
        3: lLabel.TextSettings.FontColor := TAlphaColorRec.Red;

      end;
      lLabel.Text := '';
      if Count > 0 then
        lLabel.Text := IntToStr(Count);
    end;
  end
  else if Flags[X][Y] then
  begin
    lLabel.Text := '🚩';
    lLabel.Visible := True;
  end
  else
  begin
    lLabel.Visible := False;
    Cell.Fill.Color := TAlphaColorRec.Lightgray;
  end;
end;

{ TCellData }

constructor TCellData.Create(AX, AY: Integer);
begin
  inherited Create;
  X := AX;
  Y := AY;
end;

end.
