unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Math.Vectors, FMX.Types3D, FMX.Controls3D, FMX.Objects3D,
  FMX.MaterialSources, FMX.Viewport3D, FMX.Controls.Presentation, FMX.StdCtrls,
  System.Math, FMX.Layouts;

type
  TfrmMain = class(TForm)
    Viewport3D1: TViewport3D;
    mtlSun: TTextureMaterialSource;
    mtlEarth: TLightMaterialSource;
    mtlMoon: TLightMaterialSource;
    DummyCamera: TDummy;
    DummyGeo: TDummy;
    DummyFE: TDummy;
    Camera1: TCamera;
    sphGeoSun: TSphere;
    sphGeoEarth: TSphere;
    sphGeoMoon: TSphere;
    rbHeliocentric: TRadioButton;
    rbGeoCentric: TRadioButton;
    rbFE: TRadioButton;
    Timer1: TTimer;
    dskFEEarth: TDisk;
    sphFESun: TSphere;
    sphFEMoon: TSphere;
    mtlFEEarth: TLightMaterialSource;
    LightFEEarth: TLight;
    LightFEMoon: TLight;
    DummyHelio: TDummy;
    LightHelio: TLight;
    sphEarth: TSphere;
    sphMoon: TSphere;
    sphSun: TSphere;
    LightGeo: TLight;
    chkShowAll: TCheckBox;
    dskFEEasterEgg: TDisk;
    btnResetCamera: TButton;
    btnResetOrbits: TButton;
    lblBrand: TLabel;
    Layout1: TLayout;
    chkAnimate: TCheckBox;
    mtlFEEasterEgg: TTextureMaterialSource;
    procedure FormCreate(Sender: TObject);
    procedure Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Viewport3D1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure Viewport3D1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure rbChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnResetCameraClick(Sender: TObject);
    procedure btnResetOrbitsClick(Sender: TObject);
    procedure DummyHelioRender(Sender: TObject; Context: TContext3D);
    procedure DummyGeoRender(Sender: TObject; Context: TContext3D);
    procedure DummyFERender(Sender: TObject; Context: TContext3D);
  private
    FDay: Double;
    FDayLong: Double;
    FMouseDown: TPointF;
    FOriginalRotationAngleX: Single;
    FOriginalRotationAngleY: Single;
    FOriginalZoom: Single;
    function PolarToCartesian(AReferencePoint: TPoint3D; AAngle,
      ARadius: Single): TPoint3D;
    procedure DrawCircle(Context: TContext3D; AReferencePoint: TPoint3D;
      ARadius: Single);
    procedure UpdateDisplay;
    procedure UpdateOrbits;
  public
    const
    EARTH_RADIUS = 8;
    MOON_RADIUS = 3;
    EARTH_ORBIT_DAYS = 365.256;
    MOON_ORBIT_DAYS = 27.322;

    GEO_SUN_RADIUS = 8;
    GEO_MOON_RADIUS = 3;

    FE_SUN_RADIUS = 5.5;

    DAY_INCREMENT = 1.0;
    DAY_INCREMENT_SLOW = 0.005;

    ORBIT_COLOR = TAlphaColorRec.White;
    TWO_PI = 2 * Pi;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}


// TfrmMain
// ============================================================================
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FOriginalRotationAngleX := DummyCamera.RotationAngle.X;
  FOriginalRotationAngleY := DummyCamera.RotationAngle.Y;
  FOriginalZoom := Camera1.Position.Z;

  FDay := 0;
  FDayLong := 0;

  UpdateDisplay;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.btnResetCameraClick(Sender: TObject);
begin
  DummyCamera.RotationAngle.Point := TPoint3D.Zero;
  DummyCamera.RotationAngle.X := FOriginalRotationAngleX;
  DummyCamera.RotationAngle.Y := FOriginalRotationAngleY;

  Camera1.Position.Z := FOriginalZoom;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.btnResetOrbitsClick(Sender: TObject);
begin
  FDay := 0;
  FDayLong := 0;
  UpdateOrbits;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DummyFERender(Sender: TObject; Context: TContext3D);
var
  LOffsetPoint: TPoint3D;
begin
  LOffsetPoint := dskFEEarth.Position.Point + TPoint3D.Create(0, -2, 0);
  DrawCircle(Context, LOffsetPoint, FE_SUN_RADIUS);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DummyGeoRender(Sender: TObject; Context: TContext3D);
begin
  DrawCircle(Context, sphGeoEarth.Position.Point, GEO_SUN_RADIUS);
  DrawCircle(Context, sphGeoEarth.Position.Point, GEO_MOON_RADIUS);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DummyHelioRender(Sender: TObject; Context: TContext3D);
begin
  DrawCircle(Context, sphSun.Position.Point, EARTH_RADIUS);
  DrawCircle(Context, sphEarth.Position.Point, MOON_RADIUS);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.rbChange(Sender: TObject);
begin
  UpdateDisplay;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.Timer1Timer(Sender: TObject);
begin
  if not chkAnimate.IsChecked then
    Exit;

  FDay := FDay + DAY_INCREMENT;
  FDayLong := FDayLong + DAY_INCREMENT_SLOW;
  UpdateOrbits;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.Viewport3D1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  FMouseDown := PointF(X, Y);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.Viewport3D1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  if ssLeft in Shift then
  begin
    DummyCamera.RotationAngle.X := DummyCamera.RotationAngle.X -
      ((Y - FMouseDown.Y) * 0.3);
    DummyCamera.RotationAngle.Y := DummyCamera.RotationAngle.Y +
      ((X - FMouseDown.X) * 0.3);
    FMouseDown := PointF(X, Y);
  end;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.Viewport3D1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  Camera1.Position.Z := Camera1.Position.Z + WheelDelta / 40;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.DrawCircle(Context: TContext3D; AReferencePoint: TPoint3D;
  ARadius: Single);
var
  LAngle: Single;
  LLastPoint: TPoint3D;
  LNextPoint: TPoint3D;
begin
  LAngle := 0;
  LLastPoint := PolarToCartesian(AReferencePoint, LAngle, ARadius);

  while LAngle < TWO_PI do
  begin
    LAngle := LAngle + 0.1;
    LNextPoint := PolarToCartesian(AReferencePoint, LAngle, ARadius);
    Context.DrawLine(LLastPoint, LNextPoint, 0.4, ORBIT_COLOR);
    LLastPoint := LNextPoint;
  end;
end;

// ----------------------------------------------------------------------------
function TfrmMain.PolarToCartesian(AReferencePoint: TPoint3D;
  AAngle, ARadius: Single): TPoint3D;
begin
  Result := TPoint3D.Create(
    AReferencePoint.X + cos(AAngle) * ARadius,
    AReferencePoint.Y,
    AReferencePoint.Z + sin(AAngle) * ARadius);
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.UpdateDisplay;
begin
  DummyHelio.Visible := rbHeliocentric.IsChecked or chkShowAll.IsChecked;
  LightHelio.Enabled := DummyHelio.Visible;

  DummyGeo.Visible := rbGeoCentric.IsChecked or chkShowAll.IsChecked;
  LightGeo.Enabled := DummyGeo.Visible;

  DummyFE.Visible := rbFE.IsChecked or chkShowAll.IsChecked;
  LightFEEarth.Enabled := DummyFE.Visible;
  LightFEMoon.Enabled := DummyFE.Visible;
end;

// ----------------------------------------------------------------------------
procedure TfrmMain.UpdateOrbits;
var
  LEarthAngle: Single;
  LMoonAngle: Single;
  LGeoSunAngle: Single;
  LGeoMoonAngle: Single;
  LFESunAngle: Single;
  LFEMoonAngle: Single;
  LOffsetPoint: TPoint3D;
begin
  // Heliocentric
  sphEarth.RotationAngle.Y := -FDay * 360;

  LEarthAngle := 1 / EARTH_ORBIT_DAYS * FDay * TWO_PI;
  sphEarth.Position.Point := PolarToCartesian(sphSun.Position.Point, LEarthAngle, EARTH_RADIUS);

  LMoonAngle := 1 / MOON_ORBIT_DAYS * FDay * TWO_PI;
  sphMoon.RotationAngle.Y := -RadToDeg(LMoonAngle);
  sphMoon.Position.Point := PolarToCartesian(sphEarth.Position.Point, LMoonAngle, MOON_RADIUS);

  // Geocentric
  LGeoSunAngle := -FDayLong * TWO_PI;
  sphGeoSun.Position.Point := PolarToCartesian(sphGeoEarth.Position.Point, LGeoSunAngle, GEO_SUN_RADIUS);

  LGeoMoonAngle := LGeoSunAngle - Pi;
  sphGeoMoon.RotationAngle.Y := -RadToDeg(LGeoMoonAngle);
  sphGeoMoon.Position.Point := PolarToCartesian(sphGeoEarth.Position.Point, LGeoMoonAngle, GEO_MOON_RADIUS);

  // Flat Earth
  LOffsetPoint := dskFEEarth.Position.Point + TPoint3D.Create(0, -2, 0);

  LFESunAngle := -FDayLong * TWO_PI;
  LightFEEarth.RotationAngle.X := RadToDeg(LFESunAngle) - 90;
  sphFESun.Position.Point := PolarToCartesian(LOffsetPoint, LFESunAngle, FE_SUN_RADIUS);

  LFEMoonAngle := LFESunAngle - Pi;
  LightFEMoon.RotationAngle.X := LightFEEarth.RotationAngle.X - 180;
  sphFEMoon.Position.Point := PolarToCartesian(LOffsetPoint, LFEMoonAngle, FE_SUN_RADIUS);
end;

end.
