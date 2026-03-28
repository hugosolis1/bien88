# 🌌 GradosPlanetarios — App iOS (IPA sin firmar)

Calculadora de grados planetarios precisos con efemérides VSOP87 y ELP2000-82.

## ✨ Características

- **10 planetas**: Sol, Luna, Mercurio, Venus, Marte, Júpiter, Saturno, Urano, Neptuno, Plutón
- **Puntos angulares**: Ascendente, Descendente, Medio Cielo (MC), Fondo del Cielo (IC)
- **Nodos lunares**: Nodo Norte (☊) y Nodo Sur (☋)
- **Modo Geocéntrico / Heliocéntrico** — toggle instantáneo
- **Selección de fecha y hora** precisa
- **Detección de retrogradación** (símbolo ℞)
- **Grados en formato DMS** (°  '  ") por signo zodiacal
- **Distancia en UA** (Unidades Astronómicas)
- **Configuración de ubicación geográfica** (para Asc/MC correctos)

---

## 📁 Estructura del Proyecto

```
PlanetaryGrades/
├── PlanetaryGrades.xcodeproj/
│   └── project.pbxproj
├── PlanetaryGrades/
│   ├── PlanetaryGradesApp.swift       ← Entry point @main
│   ├── Info.plist
│   ├── Assets.xcassets/
│   ├── Engine/
│   │   └── AstronomicalEngine.swift   ← Motor de cálculo VSOP87
│   ├── Models/
│   │   └── AstroViewModel.swift       ← ObservableObject
│   └── Views/
│       ├── ContentView.swift          ← UI principal
│       └── LocationSettingsView.swift ← Config lat/lon
└── codemagic.yaml                     ← Build pipeline
```

---

## 🚀 Pasos para compilar y obtener el .ipa

### 1. Crear repositorio en GitHub

```bash
cd PlanetaryGrades
git init
git add .
git commit -m "Initial commit - PlanetaryGrades app"

# En GitHub.com crea un repositorio nuevo llamado "PlanetaryGrades"
git remote add origin https://github.com/TU_USUARIO/PlanetaryGrades.git
git push -u origin main
```

### 2. Configurar Codemagic

1. Ve a **https://codemagic.io** y regístrate (plan gratuito incluye 500 min/mes)
2. Haz clic en **"Add application"**
3. Conecta tu cuenta de **GitHub**
4. Selecciona el repo **PlanetaryGrades**
5. Codemagic detectará automáticamente el `codemagic.yaml`
6. Cambia `your@email.com` en el yaml por tu email real antes de hacer push

### 3. Ejecutar el build

1. En Codemagic, selecciona el workflow **"planetary-grades-unsigned"**
2. Haz clic en **"Start build"**
3. Espera ~10-15 minutos
4. Descarga el artefacto `PlanetaryGrades_unsigned.ipa`

### 4. Instalar en iPhone con Jailbreak (iOS 15.8.2)

#### Opción A — Filza File Manager (recomendado)
```
1. Transfiere el .ipa al iPhone (AirDrop, SSH, o mediante Filza + servidor HTTP)
2. En Filza, navega hasta el .ipa
3. Toca el .ipa → "Open in..." → Selecciona el instalador
   (TrollStore, AppSync Unified, o Cydia Impactor)
```

#### Opción B — TrollStore (el más fácil para iOS 15.8.2)
```
1. Instala TrollStore si no lo tienes (compatible con iOS 15.x)
2. Abre TrollStore → "+" → selecciona el .ipa
3. Instala directamente
```

#### Opción C — SSH + AppSync Unified
```bash
# En el iPhone con SSH habilitado:
scp PlanetaryGrades_unsigned.ipa root@IP_IPHONE:/var/mobile/Documents/
# Luego instala vía Filza o iFile
```

#### Opción D — Sideloadly (desde Mac/PC)
```
1. Descarga Sideloadly desde https://sideloadly.io
2. Conecta el iPhone por USB
3. Arrastra el .ipa a Sideloadly
4. Introduce tu Apple ID (no requiere developer account)
5. Con AppSync Unified instalado en el jailbreak no expira en 7 días
```

---

## 🔧 Notas técnicas

### Motor de cálculo
- **Sol**: Jean Meeus "Astronomical Algorithms" Cap. 25
- **Luna**: ELP2000-82 truncado (20 términos longitud, 10 latitud)
- **Planetas**: VSOP87 simplificado + ecuación de Kepler iterativa (50 iteraciones)
- **Ascendant/MC**: Tiempo sidéreo local + oblicuidad de la eclíptica
- **Nodos lunares**: Fórmula de Meeus Cap. 24
- Precisión: ±0.1° para planetas exteriores, ±0.01° para Sol/Luna

### Geocéntrico vs Heliocéntrico
- **Geocéntrico**: Posición vista desde el centro de la Tierra (uso astrológico estándar)
- **Heliocéntrico**: Posición real en el espacio desde el Sol (uso astronómico)

### Retrogradación
La detección se basa en comparar la velocidad angular geocéntrica. Un planeta está retrógrado cuando su movimiento aparente en el cielo es hacia el oeste (velocidad negativa en longitud eclíptica).

---

## 📱 Requisitos

- iOS 15.0+
- iPhone o iPad
- Para IPA sin firmar: requiere jailbreak O TrollStore O AppSync Unified

---

## 🔮 Próximas mejoras posibles

- Tabla de aspectos (conjunciones, oposiciones, trígonos, etc.)
- Rueda zodiacal visual interactiva
- Carta natal guardable
- Efemérides en rango de fechas
- Chiron y asteroides principales (Ceres, Palas, Juno, Vesta)
- Exportar como PDF
