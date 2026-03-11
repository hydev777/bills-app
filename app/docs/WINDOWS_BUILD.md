# Compilar la app Flutter en Windows

## Error: `atlstr.h: No such file or directory`

El plugin **flutter_secure_storage** en Windows usa el API de credenciales de Windows y requiere la librería **ATL** (Active Template Library), que viene con Visual Studio.

### Solución recomendada: instalar el componente ATL

1. Abre **Visual Studio Installer** (busca "Visual Studio Installer" en el menú inicio).
2. Pulsa **Modificar** en tu instalación de Visual Studio 2022 (o "Build Tools for Visual Studio 2022").
3. Ve a la pestaña **Componentes individuales**.
4. En el buscador escribe **ATL**.
5. Marca **C++ ATL for latest v143 build tools (x86 and x64)** (o la versión que aparezca para tu instalación).
6. Pulsa **Modificar** y espera a que termine la instalación.
7. Cierra y vuelve a abrir la terminal, luego ejecuta de nuevo:
   ```bash
   flutter run -d windows
   ```

Si no tienes Visual Studio ni Build Tools instalados, instala primero **Visual Studio 2022** (Community es gratis) o **Build Tools for Visual Studio 2022** con el workload **"Desarrollo para el escritorio con C++"**, y después añade el componente ATL como arriba.

### Alternativa: ejecutar en otro dispositivo

Mientras tanto puedes desarrollar usando:

- **Chrome (web):** `flutter run -d chrome`
- **Android:** `flutter run -d android` (con emulador o dispositivo)

En esos targets no se usa el plugin de Windows y la compilación no requiere ATL.
