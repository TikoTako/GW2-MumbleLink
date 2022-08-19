unit GW2MumbleLinkUnit;

{******************************************************************************}
{                                                                              }
{                    MumbleLink component for Guild Wars 2                     }
{                                                                              }
{                          Copyright(c) 2022 TikoTako                          }
{                                                                              }
{               https://wiki.guildwars2.com/wiki/API:MumbleLink                }
{                 https://github.com/TikoTako/GW2-MumbleLink                   }
{                                                                              }
{                   Released under the BSD-3-Clause license:                   }
{        https://github.com/TikoTako/GW2-MumbleLink/blob/master/LICENSE        }
{                                                                              }
{******************************************************************************}

interface

uses Winapi.Windows;

type
  TVertex = packed record
    x: single;
    y: single;
    z: single;
  end;

  TContex = packed record
    serverAddress: array [0 .. 27] of byte; // 28 bytes
    mapId: uint32; // 4 bytes
    mapType: uint32; // 4 bytes
    shardId: uint32; // 4 bytes
    instance: uint32; // 4 bytes
    buildId: uint32; // 4 bytes
    uiState: uint32; // 4 bytes
    {
     uiState Bitmask:
     Bit 1 = IsMapOpen
     Bit 2 = IsCompassTopRight
     Bit 3 = DoesCompassHaveRotationEnabled
     Bit 4 = Game has focus
     Bit 5 = Is in Competitive game mode
     Bit 6 = Textbox has focus
     Bit 7 = Is in Combat
    }
    compassWidth: uint16; // 2 bytes - pixels
    compassHeight: uint16; // 2 bytes - pixels
    compassRotation: single; // 4 bytes - radians
    playerX: single; // 4 bytes - continentCoords
    playerY: single; // 4 bytes - continentCoords
    mapCenterX: single; // 4 bytes - continentCoords
    mapCenterY: single; // 4 bytes - continentCoords
    mapScale: single; // 4 bytes
    processId: uint32; // 4 bytes
    mountIndex: byte; // 1 byte
    // TContex should be 256byte
    padding: array [0 .. 170] of byte; // 171 bytes
  end;

  PMumble = ^TMumble;

  TMumble = packed record
    uiVersion: uint32; // 4 bytes
    uiTick: uint32; // 4 bytes
    fAvatarPosition: TVertex; // 3 * 4bytes
    fAvatarFront: TVertex; // 3 * 4bytes
    fAvatarTop: TVertex; // 3 * 4bytes
    name: array [0 .. 255] of WideChar; // wchar (2) * 256 bytes
    fCameraPosition: TVertex; // 3 * 4bytes
    fCameraFront: TVertex; // 3 * 4bytes
    fCameraTop: TVertex; // 3 * 4bytes
    identity: array [0 .. 255] of WideChar; // wchar (2) * 256 bytes
    context_len: uint32; // 4 bytes
    context: TContex; // unsigned char context[256];
    description: array [0 .. 2047] of WideChar; // wchar (2) * 2048 bytes
  end;

type
  TErrors = (eAlreadyOpen, eAlreadyExists, eUnknown, eNone);

  TMumbleLink = class
  strict private
    fLastError: Cardinal;
    fMumbleData: PMumble;
    fFileMappingHandle: THandle;
  public
    function Open(name: string = 'MumbleLink'): TErrors;
    procedure Close();
    property LastError: Cardinal read fLastError;
    property Data: PMumble read fMumbleData;
  end;

implementation

function TMumbleLink.Open(name: string = 'MumbleLink'): TErrors;
var
  vFMH: THandle;
  vLaE: Cardinal;
begin
  if fFileMappingHandle > 0 then
  begin
    Exit(eAlreadyOpen);
  end
  else
  begin
    vFMH := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, SizeOf(TMumble) * 8, PChar(Name));
    vLaE := GetLastError();
    if vFMH = 0 then
    begin
      if vLaE = ERROR_ALREADY_EXISTS then
        Exit(eAlreadyExists)
      else
      begin
        fLastError := vLaE;
        Exit(eUnknown);
      end;
    end
    else
    begin
      fFileMappingHandle := vFMH;
      fMumbleData := MapViewOfFile(fFileMappingHandle, FILE_MAP_ALL_ACCESS, 0, 0, 0);
      Exit(eNone);
    end;
  end;
end;

procedure TMumbleLink.Close();
begin
  if assigned(fMumbleData) then
  begin
    UnmapViewOfFile(fMumbleData);
    fMumbleData := nil;
  end;
  if fFileMappingHandle > 0 then
  begin
    CloseHandle(fFileMappingHandle);
    fFileMappingHandle := Default (THandle);
  end;
end;

end.
