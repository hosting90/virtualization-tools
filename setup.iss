[Setup]
AppId={{0AD5E7A0-92C7-4E15-9DCB-151E131C7038}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename={#MyOutputBaseFilename}
;SetupIconFile=msys.ico
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
MinVersion=6.1
ExtraDiskSpaceRequired=10485760
CloseApplications=yes
CloseApplicationsFilter=''
PrivilegesRequired=admin
AllowNetworkDrive=no
AllowRootDirectory=no
AllowUNCPath=no
InfoBeforeFile=changelog.txt
AppComments=Virtualization tools needed to optimal funnction in virtualized enviroment.
;Define in Tools -> Configure Sign Tools: "signtool.exe = "C:\Program Files (x86)\Windows Kits\8.1\bin\x64\signtool.exe" $p $p"
;SignTool - https://msdn.microsoft.com/en-US/windows/desktop/aa904949
;SignTool=signtool.exe sign /a /d $q{#MyAppName} {#MyAppVersion}$q /tr http://www.startssl.com/timestamp $f 

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "setguestrtc"; Description: "Set virtual guest RTC"; GroupDescription: "Virtualization integration services"
Name: "setwindowskms"; Description: "Activate Windows and setup KMS"; GroupDescription: "Software licensing and updates"; Check: IsKMSAvailable;
Name: "setwindowsupdate"; Description: "Enable automatic Windows Updates"; GroupDescription: "Software licensing and updates"
Name: "disableipv6privacy"; Description: "Disable IPv6 privacy extensions (RFC 4941)"; GroupDescription: "Network configuration"
Name: "disableipv6randomize"; Description: "Disable IPv6 address randomization (RFC 4941)"; GroupDescription: "Network configuration" 

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "virtio"; Description: "VirtIO Drivers"; Types: custom full; Flags: fixed restart
Name: "qemuga"; Description: "QEMU Guest Agent"; Types: custom full; Flags: restart
Name: "ballooning"; Description: "Memory ballooning service"; Types: custom full; Flags: restart; ExtraDiskSpaceRequired: 1024000
Name: "vdagent"; Description: "Spice Agent integration service"; Types: custom full; Flags: restart

[Code]
var
  GVLKWarning : Boolean;

const
  PRODUCT_ULTIMATE = $00000001;
  PRODUCT_HOME_BASIC = $00000002;
  PRODUCT_HOME_PREMIUM = $00000003;
  PRODUCT_ENTERPRISE = $00000004;
  PRODUCT_HOME_BASIC_N = $00000005;
  PRODUCT_BUSINESS = $00000006;
  PRODUCT_STANDARD_SERVER = $00000007;
  PRODUCT_DATACENTER_SERVER = $00000008;
  PRODUCT_ENTERPRISE_SERVER = $0000000A;
  PRODUCT_STARTER = $0000000B;
  PRODUCT_DATACENTER_SERVER_CORE = $0000000C;
  PRODUCT_STANDARD_SERVER_CORE = $0000000D;
  PRODUCT_ENTERPRISE_SERVER_CORE = $0000000E;
  PRODUCT_ENTERPRISE_SERVER_IA64 = $0000000F;
  PRODUCT_BUSINESS_N = $00000010;
  PRODUCT_WEB_SERVER = $00000011;
  PRODUCT_CLUSTER_SERVER = $00000012;
  PRODUCT_HOME_PREMIUM_N = $0000001A;
  PRODUCT_ENTERPRISE_N = $0000001B;
  PRODUCT_WEB_SERVER_CORE = $0000001D;
  PRODUCT_STANDARD_SERVER_V = $00000024;
  PRODUCT_DATACENTER_SERVER_V = $00000025;
  PRODUCT_ENTERPRISE_SERVER_V = $00000026;
  PRODUCT_DATACENTER_SERVER_CORE_V = $00000027;
  PRODUCT_STANDARD_SERVER_CORE_V = $00000028;
  PRODUCT_ENTERPRISE_SERVER_CORE_V = $00000029;
  PRODUCT_PROFESSIONAL = $00000030;
  PRODUCT_PROFESSIONAL_N = $00000031;
  PRODUCT_ESSENTIALS_SERVER = $00000032;
  PRODUCT_PROFESSIONAL_E = $00000045;
  PRODUCT_ENTERPRISE_E = $00000046;

function GetLastError() : LongInt;
external 'GetLastError@kernel32.dll stdcall';


function GetProductInfo(major, minor, spmajor, spminor: Integer; var product: Integer): Integer;
external 'GetProductInfo@Kernel32.dll stdcall delayload';


// Get command line argument value
// Example /myParameter=value
function GetCommandlineParam(Param: String):String;
var
  i : Integer;
  s : String;
begin
  Result := '';
  Param := UpperCase(Param);
  for i:=1 to ParamCount() do begin
    s := UpperCase(Copy(ParamStr(i), 1, Pos('=', ParamStr(i))-1));
    if(Param = s) then begin
      Result := Copy(ParamStr(i), Pos('=', ParamStr(i))+1, Length(ParamStr(i)));
      Break;
    end;
  end;
end;

// Check if command line argumen exists
// Example /myParameter value
function IsCommandlineParam(Param: String):Boolean;
var
  i : Integer;
begin
  Result := false;
  Param := UpperCase(Param);
  for i:=1 to ParamCount do begin
    if(UpperCase(ParamStr(i)) = Param) then begin
      Result := ParamStr(i);
      Break;
    end;
  end;
end;

function IsX64: Boolean;
begin
  Result := IsWin64 and (ProcessorArchitecture = paX64);
end;


function IsIA64: Boolean;
begin
  Result := IsWin64 and (ProcessorArchitecture = paIA64);
end;


function IsX86: Boolean;
begin
  Result := not IsWin64;
end;


function IsServer: Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  if (Version.ProductType = VER_NT_WORKSTATION) then
    Result := False
  else
    Result := True;
end;


function UseDriverForWindows2008R2(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  if (Version.Major = 6) and
     (Version.Minor = 1)
  then
    Result := True
  else
    Result := False;
end;

function UseDriverForWindows2012(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  if (Version.Major = 6) and
     (Version.Minor = 2)
  then
    Result := True
  else
    Result := False;
end;

function UseDriverForWindows2012R2(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  if (Version.Major = 6) and
     (Version.Minor = 3)
  then
    Result := True
  else
    Result := False;
end;

function UseDriverForWindows2016(): Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  if (Version.Major = 10) and
     (Version.Minor = 0)
  then
    Result := True
  else
    Result := False;
end;

function GetKMSServer(Default: String): String;
var
  KMS: String;
begin
  KMS := GetCommandlineParam('/KMS');
  if((KMS = '') and ('{#MyKmsServer}'<>'')) then
    KMS := '{#MyKmsServer}';
  Result := KMS;
end;

function GetGVLKKey(Default: String): String;
var
  Version: TWindowsVersion;
  Product: Integer;
begin
  Result := '';
  GetWindowsVersionEx(Version);
  if (Version.Major = 6) then begin
    GetProductInfo(Version.Major, Version.Minor, 0, 0, Product);

    if (Version.Minor = 0) then begin // Windows Vista, Windows Server 2008
      if (Version.ProductType = VER_NT_WORKSTATION) then begin // Vista
        if(Product = PRODUCT_BUSINESS) then
          Result := 'YFKBB-PQJJV-G996G-VWGXY-2V3X8';
        if(Product = PRODUCT_BUSINESS_N) then
          Result := 'HMBQG-8H2RH-C77VX-27R82-VMQBT';
        if(Product = PRODUCT_ENTERPRISE) then
          Result := 'VKK3X-68KWM-X2YGT-QR4M6-4BWMV';
        if(Product = PRODUCT_ENTERPRISE_N) then
          Result := 'VTC42-BM838-43QHV-84HX6-XJXKV';
      end else begin
        if(Product = PRODUCT_WEB_SERVER) or (Product = PRODUCT_WEB_SERVER_CORE) then
          Result := 'WYR28-R7TFJ-3X2YQ-YCY4H-M249D';
        if(Product = PRODUCT_STANDARD_SERVER) or (Product = PRODUCT_STANDARD_SERVER_CORE) then
          Result := 'TM24T-X9RMF-VWXK6-X8JC9-BFGM2';
        if(Product = PRODUCT_STANDARD_SERVER_V) or (Product = PRODUCT_STANDARD_SERVER_CORE_V) then
          Result := 'W7VD6-7JFBR-RX26B-YKQ3Y-6FFFJ';
        if(Product = PRODUCT_ENTERPRISE_SERVER) or (Product = PRODUCT_ENTERPRISE_SERVER_CORE) then
          Result := 'YQGMW-MPWTJ-34KDK-48M3W-X4Q6V';
        if(Product = PRODUCT_ENTERPRISE_SERVER_V) or (Product = PRODUCT_ENTERPRISE_SERVER_CORE_V) then
          Result := '39BXF-X8Q23-P2WWT-38T2F-G3FPG';
        if(Product = PRODUCT_CLUSTER_SERVER) then
          Result := 'RCTX3-KWVHP-BR6TB-RB6DM-6X7HP';
        if(Product = PRODUCT_DATACENTER_SERVER) or (Product = PRODUCT_DATACENTER_SERVER_CORE) then
          Result := '7M67G-PC374-GR742-YH8V4-TCBY3';
        if(Product = PRODUCT_DATACENTER_SERVER_V) or (Product = PRODUCT_DATACENTER_SERVER_CORE_V) then
          Result := '22XQ2-VRXRG-P8D42-K34TD-G3QQC';
        if(Product = PRODUCT_ENTERPRISE_SERVER_IA64) then
          Result := '4DWFP-JF3DJ-B7DTH-78FJB-PDRHK';
      end;
    end;

    if (Version.Minor = 1) then begin // Windows 7, Windows Server 2008 R2
      if (Version.ProductType = VER_NT_WORKSTATION) then begin // Windows 7
        if(Product = PRODUCT_PROFESSIONAL) then
          Result := 'FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4';
        if(Product = PRODUCT_PROFESSIONAL_N) then
          Result := 'MRPKT-YTG23-K7D7T-X2JMM-QY7MG';
        if(Product = PRODUCT_PROFESSIONAL_E) then
          Result := 'W82YF-2Q76Y-63HXB-FGJG9-GF7QX';
        if(Product = PRODUCT_ENTERPRISE) then
          Result := '33PXH-7Y6KF-2VJC9-XBBR8-HVTHH';
        if(Product = PRODUCT_ENTERPRISE_N) then
          Result := 'YDRBP-3D83W-TY26F-D46B2-XCKRJ';
        if(Product = PRODUCT_ENTERPRISE_E) then
          Result := 'C29WB-22CC8-VJ326-GHFJW-H9DH4';
      end else begin // Windows Server 2008 R2
        if(Product = PRODUCT_WEB_SERVER) or (Product = PRODUCT_WEB_SERVER_CORE) then
          Result := '6TPJF-RBVHG-WBW2R-86QPH-6RTM4';
        if(Product = PRODUCT_CLUSTER_SERVER) then
          Result := 'TT8MH-CG224-D3D7Q-498W2-9QCTX';
        if(Product = PRODUCT_STANDARD_SERVER) or (Product = PRODUCT_STANDARD_SERVER_CORE) then
          Result := '6TPJF-RBVHG-WBW2R-86QPH-6RTM4';
        if(Product = PRODUCT_ENTERPRISE_SERVER) or (Product = PRODUCT_ENTERPRISE_SERVER_CORE) then
          Result := '489J6-VHDMP-X63PK-3K798-CPX3Y';
        if(Product = PRODUCT_DATACENTER_SERVER) or (Product = PRODUCT_DATACENTER_SERVER_CORE) then
          Result := '74YFP-3QFB3-KQT8W-PMXWJ-7M648';
        if(Product = PRODUCT_ENTERPRISE_SERVER_IA64) then
          Result := 'GT63C-RJFQ3-4GMB6-BRFB9-CB83V';
      end;
    end;

    if (Version.Minor = 2) then begin // Windows 8, Windows Server 2012
      if (Version.ProductType = VER_NT_WORKSTATION) then begin // Vista
        if(Product = PRODUCT_PROFESSIONAL) then
          Result := 'NG4HW-VH26C-733KW-K6F98-J8CK4';
        if(Product = PRODUCT_PROFESSIONAL_N) then
          Result := 'XCVCF-2NXM9-723PB-MHCB7-2RYQQ';
        if(Product = PRODUCT_ENTERPRISE) then
          Result := '32JNW-9KQ84-P47T8-D8GGY-CWCK7';
        if(Product = PRODUCT_ENTERPRISE_N) then
          Result := 'JMNMF-RHW7P-DMY6X-RF3DR-X2BQT';
      end else begin
        if(Product = PRODUCT_STANDARD_SERVER) then
          Result := 'XC9B7-NBPP2-83J2H-RHMBY-92BT4';
        if(Product = PRODUCT_DATACENTER_SERVER) then
          Result := '48HP8-DN98B-MYWDG-T2DCC-8W83P';
      end;
    end;

    if (Version.Minor = 3) then begin // Windows 8.1, Windows Server 2012 R2
      if (Version.ProductType = VER_NT_WORKSTATION) then begin // Vista
        if(Product = PRODUCT_PROFESSIONAL) then
          Result := 'GCRJD-8NW9H-F2CDX-CCM8D-9D6T9';
        if(Product = PRODUCT_PROFESSIONAL_N) then
          Result := 'HMCNV-VVBFX-7HMBH-CTY9B-B4FXY';
        if(Product = PRODUCT_ENTERPRISE) then
          Result := 'MHF9N-XY6XB-WVXMC-BTDCT-MKKG7';
        if(Product = PRODUCT_ENTERPRISE_N) then
          Result := 'TT4HM-HN7YT-62K67-RGRQJ-JFFXW';
      end else begin
        if(Product = PRODUCT_STANDARD_SERVER) then
          Result := 'D2N9P-3P6X9-2R39C-7RTCD-MDVJX';
        if(Product = PRODUCT_DATACENTER_SERVER) then
          Result := 'W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9';
        if(Product = PRODUCT_ESSENTIALS_SERVER) then
          Result := 'KNC87-3J2TX-XB4WP-VCPJV-M4FWM';
      end;
    end;

    if (Version.Minor = 4) then begin // Windows 10
      if (Version.ProductType = VER_NT_WORKSTATION) then begin // Windows 10
        if(Product = PRODUCT_PROFESSIONAL) then
          Result := 'W269N-WFGWX-YVC9B-4J6C9-T83GX';
        if(Product = PRODUCT_PROFESSIONAL_N) then
          Result := 'MH37W-N47XK-V7XM9-C7227-GCQG9';
        if(Product = PRODUCT_ENTERPRISE) then
          Result := 'NPPR9-FWDCX-D2C8J-H872K-2YT43';
        if(Product = PRODUCT_ENTERPRISE_N) then
          Result := 'DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4';
      end else begin
        if(Product = PRODUCT_STANDARD_SERVER) then
          Result := '';
        if(Product = PRODUCT_DATACENTER_SERVER) then
          Result := '';
        if(Product = PRODUCT_ESSENTIALS_SERVER) then
          Result := '';
      end;
    end;

	
  end;
end;

function IsGVLKKey(): Boolean;
begin
  if (GetGVLKKey('')='') then begin
    Result := False;
	if((GVLKWarning = False) and (GetKMSServer('')<>'')) then begin
	  MsgBox('GVLK Key was not found for this system.', mbInformation, MB_OK);
	  GVLKWarning := True;
	 end;
  end else
    Result := True;
end;

function IsKMSAvailable(): Boolean;
begin
  Result := False;
  if (IsGVLKKey() and (GetKMSServer('')<>'')) then
    Result := True;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode : Integer;
begin
  GVLKWarning := False;
  Exec(
    ExpandConstant('{sys}\sc.exe'),
    'stop "BalloonService"',
    '', 
    SW_HIDE, 
    ewWaitUntilTerminated, 
    ResultCode
    );
  Exec(
    ExpandConstant('{sys}\sc.exe'),
    'stop "vdservice"',
    '', 
    SW_HIDE, 
    ewWaitUntilTerminated, 
    ResultCode
    );
  Exec(
    ExpandConstant('{sys}\sc.exe'),
    'stop "qemu-ga"',
    '', 
    SW_HIDE, 
    ewWaitUntilTerminated, 
    ResultCode
    );
  Exec(
    ExpandConstant('{sys}\sc.exe'),
    'stop "gica"',
    '', 
    SW_HIDE, 
    ewWaitUntilTerminated, 
    ResultCode
    );
  Result := '';
end;

[Files]
Source: "libglib-2.0-0.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "iconv.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "qemu-ga.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "qga-vss.tlb"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "qga-vss.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "getopt-win.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "libintl-8.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "vdservice.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "certutil.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: virtio
Source: "RedHat.cer"; DestDir: "{app}"; Flags: ignoreversion; Components: virtio
Source: "time-sync.xml"; DestDir: "{app}"; Flags: ignoreversion;
Source: "nssm.exe"; DestDir: "{app}"; Flags: ignoreversion;
Source: "gica.exe"; DestDir: "{app}"; Flags: ignoreversion;
Source: "drivers\2K8R2\amd64\*"; Excludes: "BLNSVR.*"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; Check: UseDriverForWindows2008R2
Source: "drivers\2K12R2\amd64\*"; Excludes: "BLNSVR.*"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; Check: UseDriverForWindows2012R2
Source: "drivers\2K16\amd64\*"; Excludes: "BLNSVR.*"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; Check: UseDriverForWindows2016
Source: "drivers\2K8R2\amd64\BLNSVR.*"; DestDir: "{app}"; Flags: ignoreversion; Components: ballooning; Check:UseDriverForWindows2008R2
Source: "drivers\2K12R2\amd64\BLNSVR.*"; DestDir: "{app}"; Flags: ignoreversion; Components: ballooning; Check:UseDriverForWindows2012R2 
Source: "drivers\2K16\amd64\BLNSVR.*"; DestDir: "{app}"; Flags: ignoreversion; Components: ballooning; Check:UseDriverForWindows2016 
Source: "drivers\COPYING"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio;
Source: "drivers\LICENSE"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; 
Source: "CHANGELOG.txt"; DestDir: "{app}"; DestName: "CHANGELOG.txt"; Flags: ignoreversion
Source: "DOCUMENTATION.txt"; DestDir: "{app}"; DestName: "DOCUMENTATION.txt"; Flags: ignoreversion

[InstallDelete]
Type: files; Name: "{app}\drivers\*"

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"; ValueType: dword; ValueName: AUOptions; ValueData: 4; Tasks: setwindowsupdate
                                                                                                                                                                       
[Run]
; Configure RTC
Filename: "{sys}\bcdedit.exe"; Parameters: "/set USEPLATFORMCLOCK on"; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguestrtc; StatusMsg: "Setting RTC..."
Filename: "{sys}\bcdedit.exe"; Parameters: "/set {{DEFAULT}} USEPLATFORMCLOCK on"; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguestrtc; StatusMsg: "Setting RTC..."
Filename: "{sys}\schtasks.exe"; Parameters: "/Delete /TN ""\Microsoft\Windows\Time Synchronization\SynchronizeTime"" /F"; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguestrtc; StatusMsg: "Setting NTP 1/2..."
Filename: "{sys}\schtasks.exe"; Parameters: "/Create /XML ""{app}\time-sync.xml"" /TN ""\Microsoft\Windows\Time Synchronization\SynchronizeTime"""; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguestrtc; StatusMsg: "Setting NTP 2/2..."

; Configure IPv6
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set privacy state=disabled store=active"; Flags: runhidden; Tasks: disableipv6privacy; StatusMsg: "Disabling IPv6 privacy extensions..."
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set privacy state=disabled store=persistent"; Flags: runhidden; Tasks: disableipv6privacy; StatusMsg: "Disabling IPv6 privacy extensions..."
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set global randomizeidentifiers=disabled store=active"; Flags: runhidden; Tasks: disableipv6randomize; StatusMsg: "Disabling IPv6 address randomization..."
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set global randomizeidentifiers=disabled store=persistent"; Flags: runhidden; Tasks: disableipv6randomize; StatusMsg: "Disabling IPv6 address randomization..."

; Install drivers
Filename: "{app}\certutil.exe"; Parameters: "-addstore TrustedPublisher RedHat.cer"; WorkingDir: "{app}"; Flags: runhidden; Components: virtio; StatusMsg: "Installing drivers..."
Filename: "{sys}\PnPutil.exe"; Parameters: "-i -a ""{app}\drivers\*.inf"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio; StatusMsg: "Installing drivers..."

; Install Balloon Service
Filename: "{app}\blnsvr.exe"; Parameters: "-i"; WorkingDir: "{app}\drivers"; Flags: 64bit runhidden; Components: virtio and ballooning; StatusMsg: "Installing ballooning service..."
Filename: "{sys}\sc.exe"; Parameters: "start BalloonService"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio and ballooning; StatusMsg: "Installing ballooning service..."

; Install QEMU Guest Agent service
Filename: "{app}\qemu-ga.exe"; Parameters: "--service install"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio and qemuga; StatusMsg: "Installing QEMU Guest Agent service..."
Filename: "{sys}\sc.exe"; Parameters: "start qemu-ga"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio and qemuga; StatusMsg: "Installing QEMU Guest Agent service..."
;Filename: "{sys}\sc.exe"; Parameters: "start ""QEMU Guest Agent VSS Provider"""; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio and qemuga; StatusMsg: "Installing QEMU Guest Agent VSS service..."

; Install Spice Agent service
Filename: "{app}\vdservice.exe"; Parameters: "install"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: vdagent; StatusMsg: "Installing Virtual Desktop Agent service..."
Filename: "{sys}\sc.exe"; Parameters: "config vdservice start=disabled"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: vdagent; StatusMsg: "Installing Virtual Desktop Agent service..."

; Windows Updates
Filename: "{sys}\sc.exe"; Parameters: "config wuauserv start=auto"; WorkingDir: "{app}"; Flags: runhidden; Tasks: setwindowsupdate; StatusMsg: "Enabling Windows Update..."
Filename: "{sys}\net.exe"; Parameters: "start wuauserv"; WorkingDir: "{app}"; Flags: runhidden; Tasks: setwindowsupdate; StatusMsg: "Enabling Windows Update..."

; Set KMS and activate
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /ipk {code:GetGVLKKey|''}"; Flags: runhidden; Tasks: setwindowskms; StatusMsg: "Installing KMS and activating..."; Check: IsKMSAvailable()
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /skms {code:GetKMSServer|''}"; Flags: runhidden; Tasks: setwindowskms; StatusMsg: "Installing KMS and activating..."; Check: IsKMSAvailable()
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /ato"; Flags: runhidden; Tasks: setwindowskms; StatusMsg: "Installing KMS and activating..."; Check: IsKMSAvailable()

; Install and run Guest Integration and Communication Agent
Filename: "{app}\nssm.exe"; Parameters: "stop gica"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "remove gica confirm"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "install gica ""{app}\gica.exe"" -r -i com1"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "set gica DisplayName Gica"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "set gica Description Guest Integration and Communication Agent"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "set gica Start SERVICE_AUTO_START"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."
Filename: "{app}\nssm.exe"; Parameters: "start gica"; Flags: runhidden; StatusMsg: "Installing Guest Integration and Communication Agent..."

[UninstallRun]
Filename: "{app}\qemu-ga.exe"; Parameters: "--service uninstall"; WorkingDir: "{app}"; Flags: 64bit runhidden
