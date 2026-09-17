"""Lista los ficheros de lib/ inalcanzables desde los puntos de entrada.

Recorre los `import`/`export` en cascada desde `lib/main.dart`. Lo que no
aparezca en ese recorrido no lo ejecuta nadie. Tiene en cuenta las
importaciones condicionales (`if (dart.library.io)`), que de otro modo
parecerian no usadas.
"""

import os
import re
import sys

SEP = chr(92)
ENTRY_POINTS = ["lib/main.dart"]

# Captura la ruta de import/export y tambien las alternativas condicionales.
# DOTALL porque una directiva condicional suele partirse en varias lineas.
DIRECTIVE = re.compile(r"^\s*(?:import|export)\s+(.+?);", re.M | re.S)
URI = re.compile("['\"]([^'\"]+)['\"]")


def normalize(path):
    return path.replace(SEP, "/")


def resolve(uri, from_file):
    """Convierte una URI de Dart en una ruta del proyecto, o None si es externa."""
    if uri.startswith("package:aikitchen/"):
        return "lib/" + uri[len("package:aikitchen/") :]
    if uri.startswith("package:") or uri.startswith("dart:"):
        return None
    # Ruta relativa al fichero que importa.
    base = os.path.dirname(from_file)
    return normalize(os.path.normpath(os.path.join(base, uri)))


def imports_of(path):
    src = open(path, encoding="utf-8").read()
    # Se quitan los comentarios de linea para no leer ejemplos en la prosa.
    src = "\n".join(re.sub("//.*", "", line) for line in src.split("\n"))

    found = []
    for directive in DIRECTIVE.findall(src):
        # Un import condicional lleva varias URIs; todas cuentan como usadas.
        for uri in URI.findall(directive):
            resolved = resolve(uri, path)
            if resolved:
                found.append(resolved)
    return found


def broken_imports():
    """Imports que apuntan a ficheros del proyecto que ya no existen."""
    broken = []
    for base in ("lib", "test"):
        for root, _dirs, files in os.walk(base):
            for name in files:
                if not name.endswith(".dart"):
                    continue
                path = normalize(os.path.join(root, name))
                for target in imports_of(path):
                    if not os.path.exists(target):
                        broken.append("%s -> %s" % (path, target))
    return broken


def main():
    broken = broken_imports()
    if broken:
        print("Imports rotos: %d" % len(broken))
        for item in broken:
            print("  - %s" % item)
        return 1
    print("Sin imports rotos.")

    all_files = set()
    for root, _dirs, files in os.walk("lib"):
        for name in files:
            if name.endswith(".dart"):
                all_files.add(normalize(os.path.join(root, name)))

    reached = set()
    queue = [e for e in ENTRY_POINTS if e in all_files]
    reached.update(queue)

    while queue:
        current = queue.pop()
        for target in imports_of(current):
            if target in all_files and target not in reached:
                reached.add(target)
                queue.append(target)

    orphans = sorted(all_files - reached)

    print("Ficheros en lib/: %d" % len(all_files))
    print("Alcanzables desde main.dart: %d" % len(reached))
    print("Inalcanzables: %d" % len(orphans))

    total_lines = 0
    for path in orphans:
        lines = sum(1 for _ in open(path, encoding="utf-8"))
        total_lines += lines
        print("  %5d  %s" % (lines, path))

    if orphans:
        print("Lineas muertas en total: %d" % total_lines)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
