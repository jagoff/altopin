#!/usr/bin/swift

import Cocoa
import Foundation
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var hotKey: GlobalHotKey?
    var topMostWindows: [CGWindowID: String] = [:] // WindowID -> App Name
    var windowTimers: [CGWindowID: Timer] = [:]
    var pinnedWindowPIDs: [CGWindowID: pid_t] = [:] // WindowID -> PID
    var pinnedWindowElements: [CGWindowID: AXUIElement] = [:] // WindowID -> AXUIElement
    var appActivationObserver: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Iniciando Always On Top...")
        
        // Solicitar permisos de notificaciones
        requestNotificationPermissions()
        
        // Verificar permisos de accesibilidad
        checkAccessibilityPermissions()
        
        // Crear un ícono en la barra de menú
        print("📍 Creando ícono en la barra de menú...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if statusItem?.button != nil {
            updateStatusBarIcon()
            print("✅ Ícono creado exitosamente")
        } else {
            print("❌ Error: No se pudo crear el botón del ícono")
        }
        
        // Configurar el menú
        setupMenu()
        print("📋 Menú configurado")
        
        // Registrar el atajo de teclado
        setupGlobalHotKey()
        print("⌨️  Atajo de teclado registrado: Control+Cmd+T")
        
        // Observar cambios de aplicación activa
        setupAppActivationObserver()
        print("👀 Observer de cambios de app configurado")
        
        print("✅ Aplicación lista!")
    }
    
    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error al solicitar permisos de notificaciones: \(error)")
            }
        }
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
        // Observar cuando cambia la aplicación activa
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
    }
    
    func handleAppActivation(_ notification: Notification) {
        // Cuando cambia la app activa, forzar las ventanas pinneadas al frente
        guard !topMostWindows.isEmpty else { return }
        
        print("🔄 Cambio de aplicación detectado, forzando ventanas pinneadas al frente")
        
        for (windowID, pid) in pinnedWindowPIDs {
            if let windowElement = pinnedWindowElements[windowID] {
                // Forzar la ventana al frente inmediatamente
                AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
                
                // También intentar activar la aplicación
                let app = NSRunningApplication(processIdentifier: pid)
                app?.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }
    
    func setupMenu() {
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // Título principal
        let titleItem = NSMenuItem(title: "📌 Always On Top", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        let font = NSFont.boldSystemFont(ofSize: 13)
        titleItem.attributedTitle = NSAttributedString(string: "📌 Always On Top", attributes: [.font: font])
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
        
        // Verificar si ya está pinneada
        if let existingWindowID = pinnedWindowPIDs.first(where: { $0.value == pid })?.key {
            // Despinnear
            if let appName = topMostWindows[existingWindowID] {
                topMostWindows.removeValue(forKey: existingWindowID)
                windowTimers[existingWindowID]?.invalidate()
                windowTimers.removeValue(forKey: existingWindowID)
                pinnedWindowPIDs.removeValue(forKey: existingWindowID)
                pinnedWindowElements.removeValue(forKey: existingWindowID)
                
                print("✅ \(appName) unpinned")
                showBanner(message: "\(appName): Desactivado", isSuccess: true)
            }
        } else {
            // Pinnear la app
            pinAppByPID(pid)
        }
        
        updateStatusBarIcon()
        updateMenu()
    }
    
    @objc func unpinWindowFromMenu(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? CGWindowID else { return }
        
        if let appName = topMostWindows[windowID] {
            topMostWindows.removeValue(forKey: windowID)
            windowTimers[windowID]?.invalidate()
            windowTimers.removeValue(forKey: windowID)
            pinnedWindowPIDs.removeValue(forKey: windowID)
            pinnedWindowElements.removeValue(forKey: windowID)
            
            print("✅ \(appName) unpinned desde el menú")
            showBanner(message: "\(appName): Desactivado", isSuccess: true)
            updateStatusBarIcon()
            updateMenu()
        }
    }
    
    func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }
        
        if topMostWindows.isEmpty {
            button.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Always On Top")
            button.title = ""
        } else {
            button.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Always On Top")
            button.title = " \(topMostWindows.count)"
        }
    }
    
    func setupGlobalHotKey() {
        // Control+Cmd+T para toggle de ventana actual
        hotKey = GlobalHotKey(key: .t, modifiers: [.control, .command]) { [weak self] in
            print("🔥 Atajo de teclado activado!")
            self?.toggleTopMost()
        }
        
        if hotKey != nil {
            print("✅ GlobalHotKey configurado correctamente")
        } else {
            print("❌ Error al configurar GlobalHotKey")
        }
    }
    
    @objc func toggleTopMost() {
        print("\n🔄 toggleTopMost() llamado")
        
        // Verificar permisos de accesibilidad
        let hasAccessibility = AXIsProcessTrusted()
        print("🔐 Permisos de accesibilidad: \(hasAccessibility ? "✅ Concedidos" : "❌ No concedidos")")
        
        guard hasAccessibility else {
            print("⚠️  Mostrando alerta de permisos")
            showAlert(message: "Esta aplicación necesita permisos de accesibilidad.\n\nPor favor, habilita los permisos en:\nPreferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad")
            return
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("❌ No se pudo obtener la aplicación en primer plano")
            showNotification(title: "Always On Top", subtitle: "No se pudo detectar la aplicación activa")
            return
        }
        
        print("📱 Aplicación activa: \(frontmostApp.localizedName ?? "Desconocida")")
        print("📦 Bundle ID: \(frontmostApp.bundleIdentifier ?? "Desconocido")")
        
        guard frontmostApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            print("⚠️  La aplicación activa es Always On Top mismo")
            showNotification(title: "Always On Top", subtitle: "Selecciona otra aplicación primero")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        print("🔢 PID: \(pid)")
        
        // Usar Core Graphics para obtener información de la ventana
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            print("❌ No se pudo obtener la lista de ventanas")
            showNotification(title: "Always On Top", subtitle: "No se pudo acceder a las ventanas")
            return
        }
        
        // Buscar la ventana de la aplicación activa
        var targetWindow: [String: Any]?
        for window in windowList {
            if let windowPID = window[kCGWindowOwnerPID as String] as? Int32,
               windowPID == pid,
               let layer = window[kCGWindowLayer as String] as? Int,
               layer == 0 {
                targetWindow = window
                break
            }
        }
        
        guard let window = targetWindow,
              let windowID = window[kCGWindowNumber as String] as? CGWindowID else {
            print("❌ No se pudo encontrar la ventana activa")
            showNotification(title: "Always On Top", subtitle: "No se pudo encontrar la ventana")
            return
        }
        
        print("🪟 Window ID: \(windowID)")
        
        let appName = frontmostApp.localizedName ?? "Ventana"
        let isCurrentlyTopMost = topMostWindows.keys.contains(windowID)
        
        print("🎚️  Estado actual: \(isCurrentlyTopMost ? "Always On Top" : "Normal")")
        
        // Usar AXUIElement para manipular la ventana
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard result == .success, let windowElement = focusedWindow as! AXUIElement? else {
            print("❌ No se pudo acceder a la ventana via AX")
            showNotification(title: "Always On Top", subtitle: "No se pudo acceder a la ventana")
            return
        }
        
        // Alternar el estado
        if isCurrentlyTopMost {
            // Desactivar: remover de la lista
            topMostWindows.removeValue(forKey: windowID)
            windowTimers[windowID]?.invalidate()
            windowTimers.removeValue(forKey: windowID)
            pinnedWindowPIDs.removeValue(forKey: windowID)
            pinnedWindowElements.removeValue(forKey: windowID)
            
            print("✅ Desactivado Always On Top")
            showBanner(message: "\(appName): Desactivado", isSuccess: true)
        } else {
            // Activar: agregar a la lista y guardar el PID y elemento
            topMostWindows[windowID] = appName
            pinnedWindowPIDs[windowID] = pid
            pinnedWindowElements[windowID] = windowElement
            
            // Usar AXRaise inicialmente y activar la app
            AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
            let app = NSRunningApplication(processIdentifier: pid)
            app?.activate(options: [.activateIgnoringOtherApps])
            
            print("✅ Activado Always On Top")
            showBanner(message: "\(appName): Activado ✓", isSuccess: true)
            
            // Iniciar un timer para mantener la ventana al frente de forma más agresiva
            startWindowMonitoring(windowID: windowID, pid: pid, windowElement: windowElement, appName: appName)
        }
        
        updateStatusBarIcon()
        updateMenu()
    }
    
    func pinAppByPID(_ pid: pid_t) {
        print("📌 Intentando pinnear app con PID: \(pid)")
        
        // Obtener información de la app
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            print("❌ No se pudo obtener la app con PID: \(pid)")
            return
        }
        
        let appName = app.localizedName ?? "Unknown"
        
        // Usar Core Graphics para obtener información de la ventana
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            print("❌ No se pudo obtener la lista de ventanas")
            showNotification(title: "Always On Top", subtitle: "No se pudo acceder a las ventanas")
            return
        }
        
        // Buscar la ventana de la aplicación
        var targetWindow: [String: Any]?
        for window in windowList {
            if let windowPID = window[kCGWindowOwnerPID as String] as? Int32,
               windowPID == pid,
               let layer = window[kCGWindowLayer as String] as? Int,
               layer == 0 {
                targetWindow = window
                break
            }
        }
        
        guard let window = targetWindow,
              let windowID = window[kCGWindowNumber as String] as? CGWindowID else {
            print("❌ No se pudo encontrar la ventana de la app")
            showNotification(title: "Always On Top", subtitle: "No se pudo encontrar la ventana de \(appName)")
            return
        }
        
        print("🪟 Window ID: \(windowID)")
        
        // Usar AXUIElement para manipular la ventana
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard result == .success, let windowElement = focusedWindow as! AXUIElement? else {
            print("❌ No se pudo acceder a la ventana via AX")
            showNotification(title: "Always On Top", subtitle: "No se pudo acceder a la ventana de \(appName)")
            return
        }
        
        // Activar: agregar a la lista y guardar el PID y elemento
        topMostWindows[windowID] = appName
        pinnedWindowPIDs[windowID] = pid
        pinnedWindowElements[windowID] = windowElement
        
        // Usar AXRaise inicialmente y activar la app
        AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
        app.activate(options: [.activateIgnoringOtherApps])
        
        print("✅ Activado Always On Top para \(appName)")
        showBanner(message: "\(appName): Activado ✓", isSuccess: true)
        
        // Iniciar un timer para mantener la ventana al frente
        startWindowMonitoring(windowID: windowID, pid: pid, windowElement: windowElement, appName: appName)
        
        updateStatusBarIcon()
        updateMenu()
    }
    
    func startWindowMonitoring(windowID: CGWindowID, pid: pid_t, windowElement: AXUIElement, appName: String) {
        // Cancelar timer anterior si existe
        windowTimers[windowID]?.invalidate()
        
        // Timer MUY agresivo para mantener la ventana al frente
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, self.topMostWindows.keys.contains(windowID) else {
                timer.invalidate()
                self?.windowTimers.removeValue(forKey: windowID)
                return
            }
            
            // Verificar si la app de la ventana pinneada es la activa
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.processIdentifier != pid {
                // Otra app está activa, forzar nuestra ventana al frente
                AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
                
                // Intentar activar la app de la ventana pinneada
                let app = NSRunningApplication(processIdentifier: pid)
                app?.activate(options: [.activateIgnoringOtherApps])
            } else {
                // Nuestra app está activa, solo asegurar que la ventana esté al frente
                AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al mostrar notificación: \(error)")
            }
        }
    }
    
    func showBanner(message: String, isSuccess: Bool) {
        // Mostrar en consola con formato
        let icon = isSuccess ? "✅" : "❌"
        print("\(icon) \(message)")
        
        // Intentar mostrar notificación
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.alertStyle = isSuccess ? .informational : .warning
            alert.addButton(withTitle: "OK")
            
            // Configurar ventana como flotante
            alert.window.level = .floating
        }
    }
}

// Clase para manejar atajos de teclado globales usando NSEvent
class GlobalHotKey {
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    init?(key: Key, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        print("🎹 Configurando monitor de eventos para tecla: \(key.rawValue)")
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            print("⌨️  Tecla presionada (global): \(event.keyCode), modificadores: \(event.modifierFlags.rawValue)")
            if event.keyCode == key.rawValue && event.modifierFlags.contains(modifiers) {
                print("✅ Coincidencia encontrada (global)!")
                callback()
            }
        }
        
        // También monitorear eventos locales
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("⌨️  Tecla presionada (local): \(event.keyCode), modificadores: \(event.modifierFlags.rawValue)")
            if event.keyCode == key.rawValue && event.modifierFlags.contains(modifiers) {
                print("✅ Coincidencia encontrada (local)!")
                callback()
                return nil
            }
            return event
        }
        
        print("✅ Monitores de eventos configurados")
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
