#!/usr/bin/swift

import Cocoa
import Foundation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hotKey: GlobalHotKey?
    var pinnedWindowID: CGWindowID?
    var pinnedAppName: String?
    var pinnedPID: pid_t?
    var pinnedWindowElement: AXUIElement?
    var monitorTimer: Timer?
    var appActivationObserver: NSObjectProtocol?
    
    // Helper para activar apps de manera compatible
    func activateApp(_ app: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        requestNotificationPermissions()
        checkAccessibilityPermissions()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if statusItem?.button != nil {
            updateStatusBarIcon()
        }
        
        updateMenu()
        setupGlobalHotKey()
        setupAppActivationObserver()
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showAlert(message: "Esta aplicación requiere permisos de accesibilidad para funcionar.\n\nPor favor, habilita los permisos en:\nPreferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad")
            }
        }
    }
    
    func setupAppActivationObserver() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let pinnedPID = self.pinnedPID,
                  let pinnedElement = self.pinnedWindowElement else { return }
            
            if let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                if activatedApp.processIdentifier != pinnedPID {
                    AXUIElementPerformAction(pinnedElement, kAXRaiseAction as CFString)
                    if let app = NSRunningApplication(processIdentifier: pinnedPID) {
                        self.activateApp(app)
                    }
                }
            }
        }
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Título principal
        let titleItem = NSMenuItem(title: "📌 AltoPin", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        let font = NSFont.boldSystemFont(ofSize: 13)
        titleItem.attributedTitle = NSAttributedString(string: "📌 AltoPin", attributes: [.font: font])
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Mostrar ventanas pinned
        if topMostWindows.isEmpty {
            let noWindowsItem = NSMenuItem(title: "Sin ventanas pinneadas", action: nil, keyEquivalent: "")
            noWindowsItem.isEnabled = false
            menu.addItem(noWindowsItem)
        } else {
            let pinnedTitle = NSMenuItem(title: "VENTANAS PINNEADAS", action: nil, keyEquivalent: "")
            pinnedTitle.isEnabled = false
            let smallFont = NSFont.systemFont(ofSize: 11, weight: .medium)
            pinnedTitle.attributedTitle = NSAttributedString(string: "VENTANAS PINNEADAS", attributes: [.font: smallFont, .foregroundColor: NSColor.secondaryLabelColor])
            menu.addItem(pinnedTitle)
            
            for (windowID, appName) in topMostWindows {
                let item = NSMenuItem(
                    title: "  ✓ \(appName)",
                    action: #selector(unpinWindowFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = windowID
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Apps disponibles para pinnear (excluir las ya pinneadas)
        let availableAppsItem = NSMenuItem(title: "APPS DISPONIBLES", action: nil, keyEquivalent: "")
        availableAppsItem.isEnabled = false
        let smallFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        availableAppsItem.attributedTitle = NSAttributedString(string: "APPS DISPONIBLES", attributes: [.font: smallFont, .foregroundColor: NSColor.secondaryLabelColor])
        menu.addItem(availableAppsItem)
        
        // Filtrar apps que NO están pinneadas
        let runningApps = NSWorkspace.shared.runningApplications.filter { app in
            app.activationPolicy == .regular && 
            app.bundleIdentifier != Bundle.main.bundleIdentifier &&
            !pinnedWindowPIDs.values.contains(app.processIdentifier)
        }.sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
        
        if runningApps.isEmpty {
            let noAppsItem = NSMenuItem(title: "  Todas las apps están pinneadas", action: nil, keyEquivalent: "")
            noAppsItem.isEnabled = false
            menu.addItem(noAppsItem)
        } else {
            for app in runningApps.prefix(10) {
                let appName = app.localizedName ?? "Unknown"
                
                let item = NSMenuItem(
                    title: "  ○ \(appName)",
                    action: #selector(pinAppFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = app.processIdentifier
                item.image = app.icon
                item.image?.size = NSSize(width: 16, height: 16)
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Ayuda
        let helpItem = NSMenuItem(title: "ℹ️ Atajo: ⌃⌘T - Toggle ventana actual", action: nil, keyEquivalent: "")
        helpItem.isEnabled = false
        menu.addItem(helpItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Salir",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func pinAppFromMenu(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? pid_t else { return }
        
        if let existingWindowID = pinnedWindowPIDs.first(where: { $0.value == pid })?.key {
            if let appName = topMostWindows[existingWindowID] {
                unpinWindow(windowID: existingWindowID)
                showNotification(title: appName, subtitle: "Desactivado")
            }
        } else {
            pinAppByPID(pid)
        }
        
        updateStatusBarIcon()
        updateMenu()
    }
    
    @objc func unpinWindowFromMenu(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? CGWindowID,
              let appName = topMostWindows[windowID] else { return }
        
        unpinWindow(windowID: windowID)
        showNotification(title: appName, subtitle: "Desactivado")
        updateStatusBarIcon()
        updateMenu()
    }
    
    func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }
        
        // Animación suave al cambiar
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if topMostWindows.isEmpty {
                button.animator().image = NSImage(systemSymbolName: "pin", accessibilityDescription: "AltoPin")
                button.animator().title = ""
            } else {
                button.animator().image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "AltoPin")
                button.animator().title = " \(topMostWindows.count)"
            }
        })
    }
    
    func setupGlobalHotKey() {
        hotKey = GlobalHotKey(key: .t, modifiers: [.control, .command]) { [weak self] in
            self?.toggleTopMost()
        }
    }
    
    @objc func toggleTopMost() {
        guard AXIsProcessTrusted() else {
            showAlert(message: "Esta aplicación necesita permisos de accesibilidad.\n\nPor favor, habilita los permisos en:\nPreferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad")
            return
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            showNotification(title: "AltoPin", subtitle: "Selecciona otra aplicación primero")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        
        guard let windowID = getWindowID(forPID: pid) else {
            showNotification(title: "AltoPin", subtitle: "No se pudo encontrar la ventana")
            return
        }
        
        let appName = frontmostApp.localizedName ?? "Ventana"
        let isCurrentlyTopMost = topMostWindows.keys.contains(windowID)
        
        guard let windowElement = getWindowElement(forPID: pid) else {
            showNotification(title: "AltoPin", subtitle: "No se pudo acceder a la ventana")
            return
        }
        
        if isCurrentlyTopMost {
            unpinWindow(windowID: windowID)
            showNotification(title: appName, subtitle: "Desactivado")
        } else {
            pinWindow(windowID: windowID, pid: pid, windowElement: windowElement, appName: appName)
            showNotification(title: appName, subtitle: "Activado ✓")
        }
        
        updateStatusBarIcon()
        updateMenu()
    }
    
    func pinAppByPID(_ pid: pid_t) {
        print("🎯 [1] pinAppByPID iniciado - PID: \(pid)")
        
        guard let app = NSRunningApplication(processIdentifier: pid),
              let appName = app.localizedName else {
            print("❌ [2] No se pudo obtener app/appName")
            showNotification(title: "AltoPin", subtitle: "No se pudo acceder a la aplicación")
            return
        }
        
        print("✅ [3] App encontrada: \(appName)")
        
        // Activar la app primero
        print("🚀 [4] Activando app...")
        activateApp(app)
        
        // Esperar brevemente para que la app se active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            print("⏰ [5] Después de 0.2s, obteniendo ventana...")
            guard let self = self else { return }
            
            guard let windowID = self.getWindowID(forPID: pid) else {
                print("❌ [6] No se pudo obtener windowID")
                self.showNotification(title: "AltoPin", subtitle: "No se pudo acceder a la ventana de \(appName)")
                return
            }
            print("✅ [7] WindowID: \(windowID)")
            
            guard let windowElement = self.getWindowElement(forPID: pid) else {
                print("❌ [8] No se pudo obtener windowElement")
                self.showNotification(title: "AltoPin", subtitle: "No se pudo acceder a la ventana de \(appName)")
                return
            }
            print("✅ [9] WindowElement obtenido")
            
            // Traer ventana al frente
            print("⬆️ [10] Trayendo ventana al frente...")
            AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
            
            // Pinnear
            print("📌 [11] Pinneando ventana...")
            self.pinWindow(windowID: windowID, pid: pid, windowElement: windowElement, appName: appName)
            print("✅ [12] Ventana pinneada exitosamente")
            
            // Forzar al frente agresivamente los primeros 2 segundos
            print("💪 [13] Iniciando empujones agresivos...")
            for i in 1...20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
                    if i % 5 == 0 {
                        self.activateApp(app)
                    }
                }
            }
            
            self.showNotification(title: appName, subtitle: "Activado ✓")
            self.updateStatusBarIcon()
            self.updateMenu()
        }
    }
    
    // MARK: - Helper Methods
    
    func getWindowID(forPID pid: pid_t) -> CGWindowID? {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for window in windowList {
            if let windowPID = window[kCGWindowOwnerPID as String] as? Int32,
               windowPID == pid,
               let layer = window[kCGWindowLayer as String] as? Int,
               layer == 0,
               let windowID = window[kCGWindowNumber as String] as? CGWindowID {
                return windowID
            }
        }
        return nil
    }
    
    func getWindowElement(forPID pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        
        // Primero intentar obtener la ventana enfocada
        var focusedWindow: AnyObject?
        var result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        if result == .success, let window = focusedWindow as! AXUIElement? {
            return window
        }
        
        // Si no hay ventana enfocada, obtener la primera ventana disponible
        var windowsRef: AnyObject?
        result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        if result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty {
            return windows[0]
        }
        
        return nil
    }
    
    func pinWindow(windowID: CGWindowID, pid: pid_t, windowElement: AXUIElement, appName: String) {
        topMostWindows[windowID] = appName
        pinnedWindowPIDs[windowID] = pid
        pinnedWindowElements[windowID] = windowElement
        
        AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
        if let app = NSRunningApplication(processIdentifier: pid) {
            activateApp(app)
        }
        
        startWindowMonitoring(windowID: windowID, pid: pid, windowElement: windowElement, appName: appName)
    }
    
    func unpinWindow(windowID: CGWindowID) {
        topMostWindows.removeValue(forKey: windowID)
        windowTimers[windowID]?.invalidate()
        windowTimers.removeValue(forKey: windowID)
        pinnedWindowPIDs.removeValue(forKey: windowID)
        pinnedWindowElements.removeValue(forKey: windowID)
        windowActivityTimestamps.removeValue(forKey: windowID)
    }
    
    func startWindowMonitoring(windowID: CGWindowID, pid: pid_t, windowElement: AXUIElement, appName: String) {
        windowTimers[windowID]?.invalidate()
        windowActivityTimestamps[windowID] = Date()
        
        print("🔄 [14] Timer ULTRA-AGRESIVO iniciado para \(appName)")
        
        // Timer ULTRA-AGRESIVO: 10ms, siempre fuerza al frente
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, self.topMostWindows.keys.contains(windowID) else {
                timer.invalidate()
                self?.windowTimers.removeValue(forKey: windowID)
                self?.windowActivityTimestamps.removeValue(forKey: windowID)
                return
            }
            
            // SIEMPRE traer al frente, sin importar qué
            AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
            
            // Verificar si otra app está activa
            let currentFrontApp = NSWorkspace.shared.frontmostApplication
            let currentPID = currentFrontApp?.processIdentifier ?? 0
            
            // Si NO es nuestra app, forzar activación
            if currentPID != pid {
                if let app = NSRunningApplication(processIdentifier: pid) {
                    self.activateApp(app)
                }
            }
        }
        
        windowTimers[windowID] = timer
    }
    
    
    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showNotification(title: String, subtitle: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

// Clase para manejar atajos de teclado globales usando NSEvent
class GlobalHotKey {
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    init?(key: Key, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == key.rawValue && event.modifierFlags.contains(modifiers) {
                callback()
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == key.rawValue && event.modifierFlags.contains(modifiers) {
                callback()
                return nil
            }
            return event
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// Enumeración de teclas
enum Key: UInt16 {
    case a = 0
    case b = 11
    case c = 8
    case d = 2
    case e = 14
    case f = 3
    case g = 5
    case h = 4
    case i = 34
    case j = 38
    case k = 40
    case l = 37
    case m = 46
    case n = 45
    case o = 31
    case p = 35
    case q = 12
    case r = 15
    case s = 1
    case t = 17
    case u = 32
    case v = 9
    case w = 13
    case x = 7
    case y = 16
    case z = 6
    
}

// Iniciar la aplicación
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
