# Rediseño de la interfaz de AI Kitchen

Fecha: 2026-09-17

## Contexto

La interfaz actual arrastra dos sistemas visuales superpuestos y una navegación
pensada solo para móvil vertical: una rejilla de accesos en el inicio desde la
que todo se abre apilado, sin barra de navegación persistente. En escritorio el
contenido no aprovecha el ancho y el recorrido entre secciones es largo.

Se ha generado un diseño completo con Google Stitch, con doce pantallas y un
sistema de diseño propio. Este documento fija qué se implementa de ese diseño,
qué se descarta y con qué estructura, para que la ejecución pueda repartirse
entre varios agentes sin que cada pantalla invente su propio dialecto.

Resultado buscado: la aplicación que dibuja el diseño, con las funciones que
hoy existen, más un puñado de mejoras baratas que el diseño sugiere y que el
modelo de datos ya soporta casi sin cambios.

## Alcance

### Entra

- Las doce pantallas del diseño.
- Sistema de diseño nuevo: paleta, tipografía Inter, radios, espaciado.
- Navegación con cinco destinos persistentes y raíl lateral en escritorio.
- Biblioteca de componentes reutilizables.
- Mejoras baratas: exportar el menú a la lista de la compra, categorías por
  pasillo, totales de calorías por día, regenerar una sola comida, origen de la
  receta, petición libre en el panel de IA, compartir la lista, marcar
  ingredientes mientras se cocina, velocidad de lectura por voz, creatividad del
  modelo y densidad compacta.

El marcado de ingredientes es **efímero**: vive en el estado de la pantalla y se
pierde al salir. Persistirlo exigiría una tabla por receta y no aporta lo
suficiente.

### Queda fuera, y por qué

| Elemento del diseño | Motivo |
|---|---|
| Despensa, con inventario y caducidades | Función nueva completa, no es un rediseño |
| Métricas de aprovechamiento, ahorro y caducidad | Dependen de la despensa |
| Distintivo "Sincronizado" | No hay sincronización ni cuentas |
| Avatar y cuenta de usuario | La aplicación no tiene cuentas |
| Navegación por semanas en el menú | Solo se guarda un menú, sin fechas |
| Dificultad como dato de la receta | No está en el modelo; existe solo como ajuste de IA |
| Etiquetas y colecciones | Requieren modelo, edición y filtrado propios |
| Fuentes web distintas de Lidl y Cookpad | El raspador solo sabe leer esas dos |

En favoritos, los filtros por etiqueta se sustituyen por filtros por **origen**:
Todas, Creadas por mí, Generadas con IA, Importadas de web. Usa el campo que sí
se añade y cumple la misma función de acotar la lista.

En crear receta se elimina la sección de etiquetas.

## Sistema de diseño

Sustituye por completo a `lib/theme/cooking_theme.dart`. Los `ColorScheme` se
declaran explícitos y no con `fromSeed`, para que los colores sean exactamente
los del diseño.

### Paleta, modo claro

| Token | Valor |
|---|---|
| primary | `#0059AC` |
| onPrimary | `#FFFFFF` |
| primaryContainer | `#1972D2` |
| onPrimaryContainer | `#F8F8FF` |
| secondary | `#4648D4` |
| onSecondary | `#FFFFFF` |
| secondaryContainer | `#6063EE` |
| onSecondaryContainer | `#FFFBFF` |
| tertiary | `#006184` |
| onTertiary | `#FFFFFF` |
| tertiaryContainer | `#007BA6` |
| onTertiaryContainer | `#F4FAFF` |
| error | `#BA1A1A` |
| onError | `#FFFFFF` |
| errorContainer | `#FFDAD6` |
| onErrorContainer | `#93000A` |
| surface | `#F8F9FF` |
| onSurface | `#0B1C30` |
| onSurfaceVariant | `#414752` |
| surfaceContainerLowest | `#FFFFFF` |
| surfaceContainerLow | `#EFF4FF` |
| surfaceContainer | `#E5EEFF` |
| surfaceContainerHigh | `#DCE9FF` |
| surfaceContainerHighest | `#D3E4FE` |
| outline | `#717784` |
| outlineVariant | `#C1C6D4` |
| inverseSurface | `#213145` |
| onInverseSurface | `#EAF1FF` |
| inversePrimary | `#A8C8FF` |

### Paleta, modo oscuro

| Token | Valor |
|---|---|
| primary | `#A8C8FF` |
| onPrimary | `#00315F` |
| primaryContainer | `#1972D2` |
| onPrimaryContainer | `#FFFFFF` |
| secondary | `#C0C1FF` |
| onSecondary | `#16179E` |
| secondaryContainer | `#6063EE` |
| onSecondaryContainer | `#FFFFFF` |
| tertiary | `#7BD0FF` |
| onTertiary | `#003549` |
| tertiaryContainer | `#007BA6` |
| onTertiaryContainer | `#FFFFFF` |
| error | `#FFB4AB` |
| onError | `#690005` |
| errorContainer | `#93000A` |
| onErrorContainer | `#FFDAD6` |
| surface | `#0F172A` |
| onSurface | `#F1F5F9` |
| onSurfaceVariant | `#C1C6D4` |
| surfaceContainerLowest | `#0B1220` |
| surfaceContainerLow | `#161F33` |
| surfaceContainer | `#1E293B` |
| surfaceContainerHigh | `#26334A` |
| surfaceContainerHighest | `#334155` |
| outline | `#8A91A0` |
| outlineVariant | `#334155` |
| inverseSurface | `#EAF1FF` |
| onInverseSurface | `#0B1C30` |
| inversePrimary | `#0059AC` |

### Acento de IA

No forma parte del `ColorScheme`, así que se declara como `ThemeExtension`
llamada `AiAccent`, con estos campos:

| Campo | Claro | Oscuro |
|---|---|---|
| color | `#6366F1` | `#38BDF8` |
| container | `#EEF2FF` | `#1E1B4B` |
| onContainer | `#6366F1` | `#38BDF8` |

Se usa **solo** en elementos de generación por IA: botón de modificar con IA,
botón de generar menú, generar lista y las insignias de "generado con IA".

### Tipografía

Familia Inter en toda la aplicación. Se empaqueta como recurso en
`assets/fonts/` y se declara en `pubspec.yaml`, en lugar de descargarla en
caliente: en web la descarga provoca un parpadeo al arrancar y añade una
dependencia de red que puede fallar.

Pesos necesarios: 400, 500, 600 y 700.

**Requisito previo, y es manual.** Hay que descargar Inter y dejar los cuatro
ficheros en `assets/fonts/`. Mientras no estén, la implementación puede seguir
usando `google_fonts` con Inter, y el cambio a fuente empaquetada se reduce a
tocar el tema y `pubspec.yaml`. Si se empaqueta, `google_fonts` deja de hacer
falta y sale de las dependencias.

| Estilo de Flutter | Tamaño | Interlineado | Peso |
|---|---|---|---|
| headlineLarge | 32 | 40 | 700 |
| headlineMedium | 22 | 28 | 600 |
| headlineSmall | 18 | 24 | 600 |
| titleLarge | 18 | 24 | 600 |
| titleMedium | 16 | 24 | 600 |
| titleSmall | 14 | 20 | 600 |
| bodyLarge | 16 | 24 | 400 |
| bodyMedium | 14 | 20 | 400 |
| bodySmall | 12 | 16 | 400 |
| labelLarge | 14 | 20 | 600 |
| labelMedium | 12 | 16 | 500 |
| labelSmall | 11 | 14 | 600 |

En pantallas de menos de 600 px de ancho, `headlineLarge` baja a 26 sobre 32.

Todos los estilos deben llevar color explícito. Un `TextStyle` con el color a
nulo se pinta negro, y eso ya rompió el modo oscuro una vez.

### Formas y espaciado

Radios: 4 en elementos menores, 8 en campos y botones, 12 en tarjetas, 16 en
paneles grandes, cápsula completa en fichas y barras de búsqueda.

Espaciado en múltiplos de 4: 4, 8, 12, 16 y 24. Margen lateral de 24 en
escritorio y 16 en móvil. Separación entre columnas de 16 y 12.

### Elevación

Sin sombras difusas. Las superficies se separan por tono y por un contorno de
1 px en `outlineVariant`. Solo las hojas modales y los diálogos llevan una
sombra lineal suave.

## Navegación

### Armazón

Un `AppShell` con cinco destinos persistentes:

1. Inicio
2. Buscar
3. Lista de la compra
4. Favoritos
5. Menú

Comportamiento por ancho de ventana:

| Ancho | Navegación |
|---|---|
| menos de 600 | Barra inferior de 64 px, con área segura |
| 600 a 1240 | Raíl lateral con iconos y etiquetas |
| más de 1240 | Raíl lateral extendido |

El estado de cada destino se conserva al cambiar de pestaña, con un
`IndexedStack`.

### Buscar como centro

La pantalla Buscar no es una sola vista, sino un centro con cuatro modos que se
eligen con fichas de filtro en la parte superior:

- Por nombre
- Por ingredientes
- De internet
- Desde una URL

### Pantallas apiladas

Fuera de los cinco destinos, y por tanto sin barra de navegación:

| Pantalla | Ruta |
|---|---|
| Detalle de receta | `/receta` |
| Crear receta | `/crear` |
| Ajustes | `/ajustes` |
| Registros | `/registros` |
| Vista previa de receta compartida | `/compartida` |

Los destinos usan `/inicio`, `/buscar`, `/compra`, `/favoritos` y `/menu`. Toda
navegación va con ruta nombrada para que la barra de direcciones del navegador
refleje la pantalla y el botón atrás funcione.

El panel de modificar con IA es una hoja inferior, no una ruta.

## Biblioteca de componentes

Se construyen antes que ninguna pantalla, en `lib/widgets/ui/`. Ninguna pantalla
debe declarar colores, radios ni tamaños por su cuenta: solo componer estas
piezas.

| Componente | Responsabilidad | Parámetros principales |
|---|---|---|
| `RecipeCard` | Tarjeta de receta sin foto | receta, al pulsar, si es favorita, acción de favorito, insignia opcional |
| `WebRecipeCard` | Tarjeta de resultado de internet, **con foto** | resultado web, al importar, al abrir en el navegador |
| `RecipeMetaRow` | Fila de tiempo, calorías y raciones con iconos de 16 | receta, compacta |
| `AppSearchField` | Barra de búsqueda en cápsula de 48 | controlador, texto de ayuda, al buscar, al limpiar |
| `FilterChipBar` | Fila desplazable de fichas de filtro | opciones, seleccionada, al cambiar |
| `RemovableChip` | Ficha de ingrediente eliminable de 28 | texto, al eliminar |
| `SectionHeader` | Título a la izquierda y enlace a la derecha | título, texto de acción, al pulsar |
| `AiButton` | Botón de acción de IA, con el color del acento | texto, icono, al pulsar, cargando |
| `PrimaryButton` | Botón principal de 44 | texto, icono, al pulsar, cargando |
| `AppCard` | Contenedor con contorno de 1 px y radio 12 | hijo, relleno, al pulsar |
| `EmptyState` | Estado vacío con icono, texto y acción | icono, título, descripción, acción |
| `ContentShell` | Ya existe. Ancho de lectura y márgenes | se conserva |

`RecipeCard` no muestra fotografía en ningún caso, porque las recetas generadas
por IA no tienen imagen y el modelo no la guarda. La fotografía existe solo en
`WebRecipeCard`, que pinta resultados de raspado del tipo `WebRecipeResult`, el
único que trae una dirección de imagen. Son dos componentes distintos a
propósito, y esa es la única excepción a la regla de no usar fotos.

## Pantallas

Para cada una se indica qué muestra y de dónde salen los datos. Ninguna añade
funciones que no estén en este documento.

### 1. Inicio (`/inicio`)

- Cabecera con el nombre de la aplicación y acceso a ajustes.
- Bloque "Para hoy": comida y cena del día según el menú guardado, cada una
  pulsable. Si no hay menú, estado vacío que invita a generarlo.
- Rejilla de accesos rápidos: por nombre, por ingredientes, de internet, plan
  semanal, lista de la compra, importar URL, crear receta y favoritos.
- Sección "Guardadas recientemente" con las tres últimas favoritas. Como las
  recetas no llevan fecha, se ordenan por identificador descendente, que es el
  orden de inserción.

Se elimina del diseño: la cabecera de despensa, la sección "Según tu despensa"
y el distintivo de IA activa.

### 2. Buscar (`/buscar`)

Centro con cuatro modos. Cabecera común con la barra de búsqueda.

**Por nombre**: campo de búsqueda, historial de búsquedas recientes como fichas
eliminables, resultados en `RecipeCard`.

**Por ingredientes**: los ingredientes se añaden como `RemovableChip`, botón de
generar, resultados en `RecipeCard`.

**De internet**: buscador sobre Lidl y Cookpad, con fichas para elegir fuente.
Los resultados **sí llevan fotografía**, porque el raspado la proporciona y
ayuda a elegir. Cada resultado ofrece importar con IA o abrir en el navegador.

**Desde una URL**: campo para pegar la dirección, botón de extraer, estado de
carga y la receta resultante con opción de guardarla.

### 3. Lista de la compra (`/compra`)

- Contadores de pendientes y comprados.
- Botón de generar la lista desde el menú semanal con IA.
- Campo para añadir artículo.
- Fichas de filtro por categoría, más "Todas".
- Artículos agrupados por categoría, cada uno con casilla y botón de borrar.
- Sección plegable de comprados, con texto tachado y acción de vaciar.
- Acciones inferiores: limpiar marcados y compartir lista.

### 4. Favoritos (`/favoritos`)

- Cabecera con el número de recetas guardadas y botón de importar.
- Buscador sobre las favoritas.
- Fichas de filtro por origen: Todas, Creadas por mí, Generadas con IA,
  Importadas de web.
- Lista de `RecipeCard` con el origen como insignia.
- Modo de selección múltiple con acciones de compartir y borrar.

### 5. Menú semanal (`/menu`)

- Cabecera con un único botón, que dice "Generar con IA" si no hay menú y
  "Regenerar" si ya lo hay. Se descarta el segundo botón de "Ajustar con IA" que
  dibuja el diseño, porque no define qué ajusta.
- Los siete días, cada uno con comida y cena, y el total de calorías del día,
  que se calcula sumando las dos recetas.
- Cada comida ofrece regenerar solo esa receta.
- Botón inferior de exportar los ingredientes a la lista de la compra.

Se elimina del diseño la navegación entre semanas.

### 6. Detalle de receta (`/receta`)

- Cabecera con nombre y descripción, sin fotografía.
- Fila de datos: tiempo, calorías y raciones.
- Acciones: favorito, compartir, abrir la web original si procede, y modificar
  con IA.
- Bloque de lectura en voz alta con botón de iniciar.
- Dos secciones, ingredientes y preparación. En móvil, pestañas. A partir de
  1000 px de ancho, las dos en columnas, con la preparación más ancha.
- Ingredientes con casilla para marcar, y contador de marcados.
- Pasos numerados, con el actual resaltado y los anteriores marcados.

Se elimina del diseño: la dificultad, el consejo culinario y los distintivos de
aprovechamiento y despensa.

### 7. Panel de modificar con IA

Hoja inferior, con ancho máximo de 640. Contiene las siete opciones que ya
existen como prompts, más la petición libre:

1. Cambiar raciones, con control de menos y más
2. Sistema de unidades, métrico o tazas
3. Versión exprés, con interruptor
4. Versión más saludable, con interruptor
5. Adaptar a una dieta, con fichas
6. Cambiar dificultad, con tres niveles
7. Tono de las instrucciones, con tres opciones
8. Petición personalizada en texto libre, hasta 300 caracteres

Botón inferior de generar la nueva receta.

### 8. Crear receta (`/crear`)

Formulario por secciones: datos generales, métricas esenciales con tiempo,
raciones y calorías, ingredientes en texto plano reordenables, y pasos de
preparación. Botón de guardar.

Se elimina la sección de etiquetas y el cálculo automático de calorías con IA.

### 9. Ajustes (`/ajustes`)

Secciones:

- **Motor de IA**: proveedor Groq, clave de API con campo oculto y ojo para
  mostrar, y elección de modelo entre GPT-OSS 120B y GPT-OSS 20B.
- **Acceso a webs de recetas**: plantilla del proxy. Solo visible en web.
- **Apariencia**: tema claro, oscuro o del sistema, y densidad compacta.
- **Preferencias de recetas**: número de recetas, tipos de cocina como fichas
  múltiples e idioma.
- **Voz y tono**: lectura en voz alta, velocidad de reproducción y personalidad
  de la IA.
- **Modelo**: creatividad, que fija la temperatura de la petición.
- **Diagnóstico**: acceso a los registros.

Se corrige del diseño: los proveedores Google AI, OpenAI y Ollama, y los modelos
Gemini, que no corresponden a lo que usa la aplicación.

## Cambios en los datos

Dos campos nuevos, ambos opcionales para no romper lo ya guardado.

### `Recipe.origen`

Cadena opcional con tres valores: `manual`, `ia` o `web`. Se asigna al crear la
receta. Las recetas ya guardadas lo tendrán a nulo, que se muestra como
"Generadas con IA" por ser el caso mayoritario.

### `CartItem.categoria`

Cadena opcional con el pasillo. La rellena la IA al generar la lista. Los
artículos añadidos a mano y los ya guardados quedan a nulo y se agrupan bajo
"Otros".

### Preferencias nuevas

Tres claves nuevas en `SharedPreferencesKeys`, todas con valor por defecto para
que la aplicación funcione igual si no se han tocado:

| Clave | Uso | Por defecto |
|---|---|---|
| `velocidadVoz` | Velocidad de la lectura en voz alta | `1.0` |
| `creatividad` | Temperatura de la petición a la IA | `0.1` |
| `densidadCompacta` | Reduce el relleno de listas y tarjetas | `false` |

`creatividad` sustituye a la temperatura fija que hoy lleva escrita
`GroqService`.

### Migración

- **Web**: sin trabajo. Se guarda como JSON y los lectores deben tolerar que la
  clave falte.
- **Móvil**: subir la versión de SQLite a 3 y añadir en `onUpgrade` tres
  sentencias `ALTER TABLE ... ADD COLUMN`, para `fav_recipes`, `menu` y
  `shopping_list`.

Hay que actualizar `toMap`, `fromMap`, `toJson` y `fromJson` de los dos modelos,
tolerando siempre la ausencia del campo.

## Cambios en los prompts

- **Lista de la compra**: el JSON de respuesta pasa de una lista de cadenas a
  una lista de objetos con `nombre` y `categoria`. Categorías permitidas:
  frutas y verduras, carnes y pescados, lácteos y huevos, despensa, congelados,
  bebidas y otros.
- **Nuevo**: regenerar una sola comida del menú, indicando el día, el tipo de
  comida y las recetas del resto de la semana para no repetir.
- **Modificar receta**: admitir un texto libre del usuario añadido al final.

## Verificación

Al terminar cada tanda de pantallas, y no solo al final:

```bash
flutter analyze
flutter test
python3 tool/check_balance.py lib
python3 tool/check_imports.py lib
python3 tool/check_reachable.py
```

Criterios de aceptación:

- `flutter analyze` sin errores ni advertencias.
- `flutter test` en verde, incluidas las pruebas de contraste del tema, que hay
  que ampliar con los nuevos tokens.
- Sin ficheros inalcanzables, salvo los que se eliminen a propósito.
- La aplicación abre en navegador y las cinco pestañas se recorren sin fallos.
- El texto se lee bien en modo claro y en oscuro, comprobado en las doce
  pantallas.
- A 1920 px de ancho ninguna línea de texto ocupa todo el ancho, y el detalle de
  receta muestra las dos columnas.

## Orden de ejecución

El orden importa: los tres primeros bloques son el contrato del que dependen
todas las pantallas, y conviene hacerlos con el modelo más capaz.

1. Tema y tokens, con la extensión del acento de IA y la tipografía Inter.
2. Biblioteca de componentes.
3. Armazón de navegación, con los cinco destinos y las rutas.
4. Cambios de modelo, migración y prompts.
5. Las doce pantallas, que a partir de aquí solo componen piezas existentes y
   pueden repartirse entre varios agentes en tandas sin solapamiento.
6. Retirada del código que quede inalcanzable.
