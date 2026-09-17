"""Comprobacion rapida de equilibrio de parentesis, corchetes y llaves.

No sustituye al analizador de Dart: solo detecta errores gruesos de anidamiento
introducidos al editar, que es el fallo mas probable cuando no se puede compilar.
"""

import os
import sys

PAIRS = {")": "(", "]": "[", "}": "{"}
BACKSLASH = chr(92)


def scan(path):
    src = open(path, encoding="utf-8").read()
    i = 0
    n = len(src)
    line = 1
    stack = []

    while i < n:
        c = src[i]

        if c == "\n":
            line += 1
            i += 1
            continue

        if c == "/" and i + 1 < n and src[i + 1] == "/":
            while i < n and src[i] != "\n":
                i += 1
            continue

        if c == "/" and i + 1 < n and src[i + 1] == "*":
            i += 2
            while i + 1 < n and not (src[i] == "*" and src[i + 1] == "/"):
                if src[i] == "\n":
                    line += 1
                i += 1
            i += 2
            continue

        if c in "\"'":
            triple = src[i : i + 3] in ('"""', "'''")
            quote = src[i : i + 3] if triple else c
            i += len(quote)
            while i < n:
                if src[i] == BACKSLASH:
                    i += 2
                    continue
                if src[i] == "\n":
                    line += 1
                    if not triple:
                        break
                if src[i : i + len(quote)] == quote:
                    i += len(quote)
                    break
                i += 1
            continue

        if c in "([{":
            stack.append((c, line))
            i += 1
            continue

        if c in ")]}":
            if not stack:
                return "%s:%d: cierre '%s' sin apertura" % (path, line, c)
            opener, opened_at = stack.pop()
            if opener != PAIRS[c]:
                return "%s:%d: '%s' cierra '%s' abierto en la linea %d" % (
                    path,
                    line,
                    c,
                    opener,
                    opened_at,
                )
            i += 1
            continue

        i += 1

    if stack:
        opener, opened_at = stack[-1]
        return "%s: queda sin cerrar '%s' abierto en la linea %d" % (
            path,
            opener,
            opened_at,
        )
    return None


def main():
    root_dir = sys.argv[1] if len(sys.argv) > 1 else "lib"
    problems = []
    checked = 0
    for root, _dirs, files in os.walk(root_dir):
        for name in files:
            if name.endswith(".dart"):
                checked += 1
                found = scan(os.path.join(root, name))
                if found:
                    problems.append(found)

    print("Ficheros analizados: %d" % checked)
    if problems:
        print("Desequilibrios encontrados: %d" % len(problems))
        for problem in problems:
            print(" - %s" % problem)
        return 1
    print("Sin desequilibrios.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
