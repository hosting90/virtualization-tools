#define MyAppName "Virtualization Tools"
#define MyAppVersion "1.59.0"
#define MyAppPublisher "HOSTING90 systems s.r.o."
#define MyAppURL "http://www.hosting90.cz"

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
OutputBaseFilename=virtio-setup-1-59-0
Compression=lzma2/ultra
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
MinVersion=6.1
ExtraDiskSpaceRequired=10485760
;Define in Tools -> Configure Sign Tools: "signtool.exe = signtool.exe $p"
SignTool=signtool.exe sign $f 

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "setguest"; Description: "Set virtual guest RTC"; GroupDescription: "Virtualization integration services"
Name: "setwindowskms"; Description: "Activate Windows and setup KMS"; GroupDescription: "Software licensing and updates"; Check: IsMAKKey
Name: "setwindowsupdate"; Description: "Enable automatic Windows Updates"; GroupDescription: "Software licensing and updates"
Name: "disableipv6privacy"; Description: "Disable IPv6 privacy extensions (RFC 4941)"; GroupDescription: "Network configuration"
Name: "disableipv6randomize"; Description: "Disable IPv6 address randomization (RFC 4941)"; GroupDescription: "Network configuration" 

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "virtio"; Description: "VirtIO Drivers"; Types: custom full; Flags: fixed restart
Name: "qemuga"; Description: "QEMU Guest Agent"; Types: custom full; Flags: restart
Name: "vdagent"; Description: "Spice Agent integration service"; Types: custom full; Flags: restart

[Code]
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
PRODUCT_PROFESSIONAL_E = $00000045;
PRODUCT_ENTERPRISE_E = $00000046;

function GetProductInfo(major, minor, spmajor, spminor: Integer; var product: Integer): Integer;
external 'GetProductInfo@Kernel32.dll stdcall delayload';


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
     (Version.Minor = 1) and
     (
       (Version.ProductType = VER_NT_SERVER) or
       (Version.ProductType = VER_NT_DOMAIN_CONTROLLER)
     )
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
     (Version.Minor = 2) and
     (
       (Version.ProductType = VER_NT_SERVER) or
       (Version.ProductType = VER_NT_DOMAIN_CONTROLLER)
     )
  then
    Result := True
  else
    Result := False;
end;

function GetMAKKey(Default:String): String;
var
  Version: TWindowsVersion;
  Product: Integer;
begin
  Result := Default;
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

  end;
end;

function IsMAKKey(): Boolean;
begin
  if (GetMAKKey('')='') then
    Result := False
  else
    Result := True;
end;


[Files]
Source: "libglib-2.0-0.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "libiconv-2.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "libintl-8.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "qemu-ga.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: qemuga
Source: "vdagent.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "vdservice.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: vdagent
Source: "certutil.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: virtio
Source: "RedHat.cer"; DestDir: "{app}"; Flags: ignoreversion; Components: virtio
Source: "drivers\win7\amd64\*"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; Check: UseDriverForWindows2008R2
Source: "drivers\win8\amd64\*"; DestDir: "{app}\drivers"; Flags: ignoreversion; Components: virtio; Check: UseDriverForWindows2012
Source: "CHANGELOG.txt"; DestDir: "{app}"; DestName: "CHANGELOG.txt"; Flags: ignoreversion

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"; ValueType: dword; ValueName: AUOptions; ValueData: 4; Tasks: setwindowsupdate
                                                                                                                                                                       
[Run]
; Configure RTC
Filename: "{sys}\bcdedit.exe"; Parameters: "/set USEPLATFORMCLOCK on"; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguest
Filename: "{sys}\bcdedit.exe"; Parameters: "/set {{DEFAULT}} USEPLATFORMCLOCK on"; WorkingDir: "{sys}"; Flags: runhidden; Tasks: setguest

; Configure IPv6
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set privacy state=disabled store=active"; Flags: runhidden; Tasks: disableipv6privacy
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set privacy state=disabled store=persistent"; Flags: runhidden; Tasks: disableipv6privacy
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set global randomizeidentifiers=disabled store=active"; Flags: runhidden; Tasks: disableipv6randomize
Filename: "{sys}\netsh.exe"; Parameters: "interface ipv6 set global randomizeidentifiers=disabled store=persistent"; Flags: runhidden; Tasks: disableipv6randomize

; Install drivers
Filename: "{app}\certutil.exe"; Parameters: "-addstore TrustedPublisher RedHat.cer"; WorkingDir: "{app}"; Flags: runhidden; Components: virtio
Filename: "{sys}\PnPutil.exe"; Parameters: "-i -a ""{app}\drivers\*.inf"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: virtio

; Install QEMU Guest Agent service
Filename: "{app}\qemu-ga.exe"; Parameters: "--service install"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: qemuga

; Install Spice Agent service
Filename: "{app}\vdservice.exe"; Parameters: "install"; WorkingDir: "{app}"; Flags: 64bit runhidden; Components: vdagent

; Windows Updates
Filename: "{sys}\sc.exe"; Parameters: "config wuauserv start= auto"; WorkingDir: "{app}"; Flags: runhidden; Tasks: setwindowsupdate                                                                           
Filename: "{sys}\net.exe"; Parameters: "start wuauserv"; WorkingDir: "{app}"; Flags: runhidden; Tasks: setwindowsupdate

; Set KMS and activate
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /ipk {code:GetMAKKey|''}"; Flags: runhidden; Tasks: setwindowskms
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /skms kms.hosting90.net"; Flags: runhidden; Tasks: setwindowskms
Filename: "{sys}\cscript.exe"; Parameters: "slmgr.vbs /ato"; Flags: runhidden; Tasks: setwindowskms 

[UninstallRun]
Filename: "{app}\qemu-ga.exe"; Parameters: "--service uninstall"; WorkingDir: "{app}"; Flags: 64bit runhidden
