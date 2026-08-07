program SmartEats;

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Forms,
  Vcl.Dialogs,
  uSmartEatsBootstrap in 'uSmartEatsBootstrap.pas',
  uDataModule in 'uDataModule.pas' {dmData: TDataModule},
  uSmartEatsService in 'uSmartEatsService.pas',
  uWebHoof in 'uWebHoof.pas' {frmWebHoof};

{$R 'resources\SmartEats.res'}
{$R 'resources\SmartEatsAssets.res'}

begin
  Application.Initialize;
  Application.Title := 'SmartEats Bestellings en Spyskaartbestuur';
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdmData, dmData);
  try
    dmData.KoppelDatabasis;
    Application.CreateForm(TfrmWebHoof, frmWebHoof);
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  Application.Run;
end.
