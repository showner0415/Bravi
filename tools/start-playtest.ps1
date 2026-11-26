# Run from Windows PowerShell as a background task. The selected desktop is
# private to this run and is never switched onto the user's monitor.
[CmdletBinding()]
param([string]$Godot, [string]$SessionLog)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if ($SessionLog) {
    $gameArgs = @('--log-file', $SessionLog, '--', '--bravi-virtual-mouse')
    try {
        & "$project\play.ps1" -Godot $Godot -GodotArgs $gameArgs *> "$SessionLog.launch.txt"
        exit $LASTEXITCODE
    } catch {
        $_ | Out-File -Append "$SessionLog.launch.txt"
        exit 1
    }
}
$run = 'BraviPlaytest-' + [guid]::NewGuid().ToString('N')
$log = Join-Path ([IO.Path]::GetTempPath()) "$run.log"
$command = '"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" -SessionLog "{2}"' -f $shell, $PSCommandPath, $log
if ($Godot) { $command += ' -Godot "{0}"' -f (Resolve-Path -LiteralPath $Godot).Path }

if (!('BraviPlaytest.Desktop' -as [type])) {
    Add-Type -Namespace BraviPlaytest -Name Desktop -MemberDefinition @'
        [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
        struct StartupInfo {
            public int cb;
            public string reserved, desktop, title;
            public int x, y, width, height, charsX, charsY, fill, flags;
            public short show, reservedSize;
            public IntPtr reservedData, input, output, error;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct ProcessInfo { public IntPtr process, thread; public int pid, tid; }
        [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        static extern IntPtr CreateDesktop(string name, IntPtr device, IntPtr mode, uint flags, uint access, IntPtr security);
        [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr desktop);
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        static extern bool CreateProcess(string exe, System.Text.StringBuilder command, IntPtr pSec, IntPtr tSec,
            bool inherit, uint flags, IntPtr env, string cwd, ref StartupInfo start, out ProcessInfo proc);
        [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
        delegate bool EnumCallback(IntPtr window, IntPtr data);
        [DllImport("user32.dll")] static extern bool EnumDesktopWindows(IntPtr desktop, EnumCallback cb, IntPtr data);
        [DllImport("user32.dll", CharSet=CharSet.Unicode)]
        static extern int GetWindowText(IntPtr hwnd, System.Text.StringBuilder title, int size);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out int pid);
        IntPtr _desktop;
        public System.Diagnostics.Process Runner;
        public int GamePid() {
            int pid = 0;
            EnumDesktopWindows(_desktop, delegate(IntPtr hwnd, IntPtr data) {
                var title = new System.Text.StringBuilder(128);
                GetWindowText(hwnd, title, title.Capacity);
                if (title.ToString() != "Bravi" && title.ToString() != "Bravi (DEBUG)") return true;
                GetWindowThreadProcessId(hwnd, out pid);
                return false;
            }, IntPtr.Zero);
            return pid;
        }
        public void Close() { Runner.Dispose(); CloseDesktop(_desktop); }
        public static Desktop Start(string desktopName, string exe, string command, string cwd) {
            // Desktop access excludes switching to this desktop.
            IntPtr desktop = CreateDesktop(desktopName, IntPtr.Zero, IntPtr.Zero, 0, 0x00C3, IntPtr.Zero);
            if (desktop == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();
            try {
                var start = new StartupInfo { cb=Marshal.SizeOf(typeof(StartupInfo)), desktop=desktopName };
                ProcessInfo pi;
                if (!CreateProcess(exe, new System.Text.StringBuilder(command), IntPtr.Zero, IntPtr.Zero,
                    false, 0x08000000, IntPtr.Zero, cwd, ref start, out pi)) throw new System.ComponentModel.Win32Exception();
                try {
                    var child = System.Diagnostics.Process.GetProcessById(pi.pid);
                    // Acquire a managed process handle before releasing the native one.
                    var handle = child.Handle;
                    return new Desktop { Runner=child, _desktop=desktop };
                } finally { CloseHandle(pi.thread); CloseHandle(pi.process); }
            } catch { CloseDesktop(desktop); throw; }
        }
'@
}
$originalSave = $env:BRAVI_SAVE_PATH
$originalSettings = $env:BRAVI_SETTINGS_PATH
try {
    if (!$originalSave) { $env:BRAVI_SAVE_PATH = 'user://bravi_playtest_save.json' }
    if (!$originalSettings) { $env:BRAVI_SETTINGS_PATH = 'user://bravi_playtest_settings.json' }
    $session = [BraviPlaytest.Desktop]::Start($run, $shell, $command, $project)
} finally { $env:BRAVI_SAVE_PATH = $originalSave; $env:BRAVI_SETTINGS_PATH = $originalSettings }
Write-Output "Game log: $log"
try {
    while (!$session.Runner.WaitForExit(250)) {
        $gamePid = $session.GamePid()
        if ($gamePid) {
            Write-Output "Game PID: $gamePid"
            $session.Runner.WaitForExit()
            break
        }
    }
    $code = $session.Runner.ExitCode
    Write-Output "Playtest exit: $code"
    if ($code -ne 0 -and (Test-Path "$log.launch.txt")) { Get-Content "$log.launch.txt" | Select-Object -Last 20 }
} finally { $session.Close() }
exit $code
