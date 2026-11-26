# Coordinates are in pixels of this process's client-area PNG.
# Use Windows PowerShell. Multiple calls in one shell reuse the native bindings.
# Actions: Shot, Move, Click, GuardDown, GuardUp, Key, Close, DoubleClick, FocusOut, FocusIn, Quit.
# DoubleClick: two left press/release pairs, 150 ms between the presses, no screenshot between them.
# FocusOut/FocusIn only SIMULATE focus loss/gain by posting WM_ACTIVATEAPP and WM_ACTIVATE.
# They are NOT a real OS focus change (the foreground window and the engine's own
# message order, e.g. WM_KILLFOCUS, differ from a real Alt+Tab). Report results as a simulation.
# Close posts WM_CLOSE once. Quit posts WM_CLOSE, waits 1000 ms, posts it once more if the
# window is still there, waits 2000 ms, and throws if the window still exists.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$GamePid,
    [ValidateSet('Shot', 'Move', 'Click', 'GuardDown', 'GuardUp', 'Key', 'Close', 'DoubleClick', 'FocusOut', 'FocusIn', 'Quit')][string]$Action = 'Shot',
    [int]$X = -1,
    [int]$Y = -1,
    [ValidateSet('Enter', 'Escape', 'W', 'S', 'Tab', 'Space', 'R', 'F1')][string]$Key,
    [switch]$GuardHeld,
    [switch]$Isolated,
    [string]$Screenshot,
    [ValidateRange(0, 5000)][int]$SettleMs = 150
)

$ErrorActionPreference = 'Stop'
if ($Action -eq 'Shot' -and !$Screenshot) { throw 'Shot requires -Screenshot <PNG path>.' }
if ($Action -eq 'Key' -and !$Key) { throw 'Key requires -Key <name>.' }
if ($Screenshot) { $Screenshot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Screenshot) }

if (!('BraviPlaytest.WindowInput' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading;

namespace BraviPlaytest {
    public static class WindowInput {
        [StructLayout(LayoutKind.Sequential)]
        public struct Rect { public int Left, Top, Right, Bottom; }
        [StructLayout(LayoutKind.Sequential)]
        public struct Point { public int X, Y; }
        delegate bool WindowCallback(IntPtr hwnd, IntPtr data);
        [DllImport("user32.dll")] static extern bool EnumThreadWindows(uint thread, WindowCallback callback, IntPtr data);
        [DllImport("user32.dll", CharSet=CharSet.Unicode)]
        static extern int GetWindowText(IntPtr hwnd, System.Text.StringBuilder title, int size);
        delegate bool DesktopCallback([MarshalAs(UnmanagedType.LPWStr)] string name, IntPtr data);
        [DllImport("user32.dll")] static extern IntPtr GetProcessWindowStation();
        [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern bool EnumDesktops(IntPtr station, DesktopCallback cb, IntPtr data);
        [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern IntPtr OpenDesktop(string name, uint flags, bool inherit, uint access);
        [DllImport("user32.dll")] static extern bool CloseDesktop(IntPtr desktop);
        [DllImport("user32.dll")] static extern bool EnumDesktopWindows(IntPtr desktop, WindowCallback cb, IntPtr data);
        [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out int pid);
        [DllImport("user32.dll", SetLastError=true)] static extern bool SetThreadDesktop(IntPtr desktop);
        [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
        [DllImport("user32.dll")] static extern IntPtr GetThreadDesktop(uint thread);
        public static IntPtr CurrentDesktop() { return GetThreadDesktop(GetCurrentThreadId()); }
        public static void RestoreDesktop(IntPtr original, IntPtr opened) {
            if (!SetThreadDesktop(original)) throw new System.ComponentModel.Win32Exception();
            CloseDesktop(opened);
        }
        static IntPtr FindGameWindow(System.Diagnostics.Process process, bool isolated, out IntPtr attached) {
            attached = IntPtr.Zero;
            IntPtr result = IntPtr.Zero;
            if (isolated) {
                IntPtr foundDesktop = IntPtr.Zero;
                EnumDesktops(GetProcessWindowStation(), delegate(string name, IntPtr data) {
                    if (!System.Text.RegularExpressions.Regex.IsMatch(name, @"^BraviPlaytest-[a-f0-9]{32}$")) return true;
                    var desktop = OpenDesktop(name, 0, false, 0x00C3);
                    if (desktop == IntPtr.Zero) return true;
                    try {
                        EnumDesktopWindows(desktop, delegate(IntPtr hwnd, IntPtr unused) {
                            int pid;
                            GetWindowThreadProcessId(hwnd, out pid);
                            if (pid != process.Id) return true;
                            var title = new System.Text.StringBuilder(256);
                            GetWindowText(hwnd, title, title.Capacity);
                            if (title.ToString() != "Bravi" && title.ToString() != "Bravi (DEBUG)") return true;
                            result = hwnd;
                            return false;
                        }, IntPtr.Zero);
                        if (result != IntPtr.Zero) foundDesktop = desktop;
                    } finally { if (foundDesktop != desktop) CloseDesktop(desktop); }
                    return result == IntPtr.Zero;
                }, IntPtr.Zero);
                if (foundDesktop != IntPtr.Zero) {
                    if (!SetThreadDesktop(foundDesktop)) {
                        var error = new System.ComponentModel.Win32Exception();
                        CloseDesktop(foundDesktop);
                        throw error;
                    }
                    attached = foundDesktop;
                }
                return result;
            }
            foreach (System.Diagnostics.ProcessThread thread in process.Threads) {
                EnumThreadWindows((uint)thread.Id, delegate(IntPtr hwnd, IntPtr data) {
                    var title = new System.Text.StringBuilder(256);
                    GetWindowText(hwnd, title, title.Capacity);
                    if (title.ToString() == "Bravi" || title.ToString() == "Bravi (DEBUG)") {
                        result = hwnd;
                        return false;
                    }
                    return true;
                }, IntPtr.Zero);
                if (result != IntPtr.Zero) break;
            }
            return result;
        }
        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr window, out Rect rect);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr window, out Rect rect);
        [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr window, ref Point origin);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr window);
        [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr window, IntPtr dc, uint flags);
        [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mode);
        [DllImport("user32.dll", SetLastError=true)]
        static extern bool PostMessage(IntPtr window, uint msg, IntPtr wParam, IntPtr lParam);
        public static void Post(IntPtr window, uint msg, int value, int data) {
            if (!PostMessage(window, msg, (IntPtr)value, (IntPtr)data))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        }
        public static void Run(int pid, bool isolated, string action, int x, int y, int key,
                               bool guardHeld, string image, int settleMs) {
            Exception error = null;
            // A PowerShell host thread can own an HWND. Windows only permits a
            // thread without windows or hooks to attach to another desktop.
            var worker = new Thread(delegate() {
                var original = CurrentDesktop();
                IntPtr attached = IntPtr.Zero;
                try {
                    using (var game = Process.GetProcessById(pid)) {
                        if (!game.ProcessName.StartsWith("Godot", StringComparison.OrdinalIgnoreCase))
                            throw new InvalidOperationException("The PID must identify a Godot game.");
                        var window = FindGameWindow(game, isolated, out attached);
                        if (window == IntPtr.Zero) throw new InvalidOperationException("No matching Bravi window on the selected desktop.");
                        SetThreadDpiAwarenessContext((IntPtr)(-4));
                        Perform(window, action, x, y, key, guardHeld, image, settleMs);
                    }
                } catch (Exception ex) { error = ex; }
                finally {
                    if (attached != IntPtr.Zero) {
                        try { RestoreDesktop(original, attached); }
                        catch (Exception ex) { if (error == null) error = ex; }
                    }
                }
            });
            worker.Start();
            worker.Join();
            if (error != null) throw new InvalidOperationException(error.Message, error);
        }
        [DllImport("user32.dll")] static extern bool IsWindow(IntPtr window);
        static bool WaitGone(IntPtr window, int ms) {
            for (int waited = 0; waited < ms; waited += 50) {
                if (!IsWindow(window)) return true;
                Thread.Sleep(50);
            }
            return !IsWindow(window);
        }
        static void Quit(IntPtr window) {
            Post(window, 0x0010, 0, 0);
            if (WaitGone(window, 1000)) return;
            try { Post(window, 0x0010, 0, 0); }
            catch (System.ComponentModel.Win32Exception) { if (!IsWindow(window)) return; throw; }
            if (!WaitGone(window, 2000)) throw new InvalidOperationException("window did not close");
        }
        static void Perform(IntPtr window, string action, int x, int y, int key,
                            bool guardHeld, string image, int settleMs) {
            if (action == "close") { Post(window, 0x0010, 0, 0); return; }
            if (action == "quit") { Quit(window); return; }
            if (action == "focusout" || action == "focusin") {
                int on = action == "focusin" ? 1 : 0;
                Post(window, 0x001C, on, 0);
                Post(window, 0x0006, on, 0);
                return;
            }
            Rect area;
            if (IsIconic(window) || !GetClientRect(window, out area))
                throw new InvalidOperationException("The game window must be open and restored.");
            int mask = guardHeld || action == "guardup" ? 2 : 0;
            if (action == "key") {
                int scan = ((int)MapVirtualKey((uint)key, 0) << 16) | 1;
                Post(window, 0x0100, key, scan);
                Thread.Sleep(50);
                Post(window, 0x0101, key, scan | unchecked((int)0xC0000000));
            } else if (action != "shot") {
                if (x < 0 || y < 0 || x >= area.Right || y >= area.Bottom)
                    throw new ArgumentException("Point is outside the game window.");
                int point = (y << 16) | x;
                Post(window, 0x0200, mask, point);
                switch (action) {
                    case "click":
                        Post(window, 0x0201, mask | 1, point);
                        Thread.Sleep(50);
                        Post(window, 0x0202, mask, point);
                        break;
                    case "doubleclick":
                        Post(window, 0x0201, mask | 1, point);
                        Thread.Sleep(50);
                        Post(window, 0x0202, mask, point);
                        Thread.Sleep(100);
                        Post(window, 0x0201, mask | 1, point);
                        Thread.Sleep(50);
                        Post(window, 0x0202, mask, point);
                        break;
                    case "guarddown": Post(window, 0x0204, 2, point); break;
                    case "guardup": Post(window, 0x0205, 0, point); break;
                }
            }
            if (String.IsNullOrEmpty(image)) return;
            if (action != "shot") Thread.Sleep(settleMs);
            Rect bounds;
            var origin = new Point();
            if (!GetWindowRect(window, out bounds) || !ClientToScreen(window, ref origin))
                throw new InvalidOperationException("Cannot locate the game client area.");
            using (var bitmap = new Bitmap(bounds.Right - bounds.Left, bounds.Bottom - bounds.Top)) {
                using (var graphics = Graphics.FromImage(bitmap)) {
                    var dc = graphics.GetHdc();
                    try {
                        if (!PrintWindow(window, dc, 2)) throw new InvalidOperationException("Game capture failed.");
                    } finally { graphics.ReleaseHdc(dc); }
                }
                var crop = new Rectangle(origin.X - bounds.Left, origin.Y - bounds.Top, area.Right, area.Bottom);
                using (var client = bitmap.Clone(crop, bitmap.PixelFormat)) client.Save(image, ImageFormat.Png);
            }
        }
    }
}
'@
}
$keys = @{Enter=13; Escape=27; W=87; S=83; Tab=9; Space=32; R=82; F1=112}
$code = if ($Key) { $keys[$Key] } else { 0 }
$private = $Isolated -or $Action -in 'Move','GuardDown','GuardUp','Close','DoubleClick','FocusOut','FocusIn','Quit'
[BraviPlaytest.WindowInput]::Run($GamePid, $private, $Action.ToLowerInvariant(), $X, $Y, $code, $GuardHeld, $Screenshot, $SettleMs)
if ($Screenshot) { Write-Output $Screenshot }

