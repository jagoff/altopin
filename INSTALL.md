# 🚀 Instalación de AltoPin

## Método 1: Una Línea (Más Rápido)

Copia y pega esto en tu terminal:

```bash
git clone https://github.com/tu-usuario/altopin.git && cd altopin && bash build.sh && open build/AlwaysOnTop.app
```

## Método 2: Paso a Paso

### 1. Descarga el código

```bash
git clone https://github.com/tu-usuario/altopin.git
cd altopin
```

### 2. Compila la aplicación

```bash
bash build.sh
```

### 3. Ejecuta la aplicación

**Opción A: Solo probar**
```bash
open build/AlwaysOnTop.app
```

**Opción B: Instalar en Applications**
```bash
cp -r build/AlwaysOnTop.app /Applications/
open /Applications/AlwaysOnTop.app
```

## ⚙️ Configuración Inicial

La primera vez que ejecutes AltoPin:

1. macOS te pedirá **permisos de accesibilidad**
2. Ve a: **Preferencias del Sistema** → **Seguridad y Privacidad** → **Privacidad** → **Accesibilidad**
3. Haz clic en el **candado** 🔒 para hacer cambios
4. Agrega **AlwaysOnTop** y marca la casilla ✅
5. Reinicia la aplicación

## 🎯 Uso

- Presiona **Control+Cmd+T** en cualquier ventana para pinnearla
- Presiona **Control+Cmd+T** de nuevo para despinnearla
- O usa el ícono 📌 en la barra de menú

## ❓ Problemas Comunes

### "La aplicación no puede abrirse porque es de un desarrollador no identificado"

```bash
sudo xattr -rd com.apple.quarantine build/AlwaysOnTop.app
```

### "No funciona el atajo de teclado"

Verifica que los permisos de accesibilidad estén habilitados (ver Configuración Inicial).

---

**¿Necesitas ayuda?** Abre un [issue en GitHub](https://github.com/tu-usuario/altopin/issues)
