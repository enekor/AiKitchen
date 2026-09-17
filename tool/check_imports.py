"""Comprueba que los simbolos compartidos del proyecto esten importados.

Complementa a check_balance.py: detecta el otro fallo tipico al editar sin
poder compilar, que es usar un simbolo y olvidar su import.
"""

import os
import re
import sys

SEP = chr(92)

NEEDS = {
    "Spacing.": "theme/cooking_theme.dart",
    "AppRadius.": "theme/cooking_theme.dart",
    "ContentWidth.": "theme/cooking_theme.dart",
    "Breakpoints.": "theme/cooking_theme.dart",
    "ContentShell(": "widgets/content_shell.dart",
    "SliverContentShell(": "widgets/content_shell.dart",
    "CorsProxy.": "services/cors_proxy.dart",
    "openExternalUrl(": "services/external_link_service.dart",
    "themeController": "theme/theme_controller.dart",
    "appStorage": "services/storage/app_storage.dart",
    "RecipeFromFileService(": "services/recipe_from_file_service.dart",
    "RecipeScreenArguments(": "models/recipe_screen_arguments.dart",
    "TextFieldSetting(": "widgets/setting_widget.dart",
    "WidgetService.": "services/widget_service.dart",
    "LogFileService(": "services/log_file_service.dart",
    "ShareRecipeService(": "services/share_recipe_service.dart",
    "kIsWeb": "foundation.dart",
    "debugPrint(": "foundation.dart",
}


def main():
    root_dir = sys.argv[1] if len(sys.argv) > 1 else "lib"
    problems = []

    for root, _dirs, files in os.walk(root_dir):
        for name in files:
            if not name.endswith(".dart"):
                continue
            path = os.path.join(root, name).replace(SEP, "/")
            src = open(path, encoding="utf-8").read()

            lines = src.split("\n")
            # Se ignoran los comentarios para no contar menciones en prosa.
            body = "\n".join(re.sub("//.*", "", line) for line in lines)
            imports = "\n".join(
                line
                for line in lines
                if line.startswith("import ") or line.startswith("export ")
            )

            for symbol, module in NEEDS.items():
                if symbol not in body:
                    continue
                if path.endswith(module):
                    continue
                # material.dart reexporta foundation, asi que vale igual.
                if module == "foundation.dart" and "material.dart" in imports:
                    continue
                if module.split("/")[-1] in imports:
                    continue
                problems.append(
                    "%s: usa %s sin importar %s" % (path, symbol, module)
                )

    if problems:
        print("Imports que faltan: %d" % len(problems))
        for problem in problems:
            print(" - %s" % problem)
        return 1
    print("Todos los simbolos comprobados estan importados.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
