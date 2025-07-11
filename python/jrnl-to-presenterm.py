#!/usr/bin/env python3
"""
Convertidor de JSON exportado de jrnl a formato Markdown para presenterm.
Lee desde stdin y escribe a stdout.
"""

import json
import sys
import argparse
import re
from typing import Dict, List, Any


def remove_tag_line(body: str) -> str:
    """
    Elimina las líneas finales si contienen solo etiquetas (@tag o #tag).
    """
    lines = body.strip().split("\n")
    if not lines:
        return body

    # Iterar desde el final eliminando líneas que contienen solo etiquetas
    while lines:
        last_line = lines[-1].strip()
        if not last_line:
            lines.pop()
            continue

        # Comprobar si todas las palabras en la línea son etiquetas
        words = last_line.split()
        if all(word.startswith("@") or word.startswith("#") for word in words):
            lines.pop()
        else:
            break

    return "\n".join(lines).strip()


def create_title_separator(title: str) -> str:
    """
    Crea una línea de separación con '=' de la misma longitud que el título.
    """
    return "=" * len(title)


def format_entry(
    entry: Dict[str, Any], include_date: bool = False, include_time: bool = False
) -> str:
    """
    Formatea una entrada individual en markdown.
    """
    result = []

    # Cuerpo sin línea de etiquetas
    body = entry.get("body", "")
    clean_body = remove_tag_line(body)

    has_cover = False
    # Verificar si el cuerpo comienza con un nuevo slide
    if clean_body:
        lines = list(filter(lambda line: line.strip(), clean_body.split("\n", 2)))
        if len(lines) > 1:
            first_line, second_line = lines[0].strip(), lines[1].strip()
            if first_line and all(c in "=-" for c in second_line):
                result.append("<!-- jump_to_middle -->")
                result.append("<!-- alignment: center -->")
                has_cover = True

    # Título con separador
    title = entry.get("title", "Sin título")
    result.append(title)
    result.append(create_title_separator(title))
    if not has_cover:
        result.append("")  # Línea vacía después del separador

    # Fecha y hora si se solicitan
    if include_time or include_date:
        datetime_parts = []
        if include_date:
            datetime_parts.append(entry.get("date", ""))
        if include_time:
            datetime_parts.append(entry.get("time", ""))

        if datetime_parts:
            datetime_str = " ".join(filter(None, datetime_parts))
            result.append(f"**{datetime_str}**")
            result.append("")

    if clean_body:
        result.append(clean_body)
        result.append("")

    return "\n".join(result)


def create_tags_summary(tags: Dict[str, int]) -> str:
    """
    Crea un resumen de etiquetas.
    """
    if not tags:
        return ""

    result = []
    result.append("Resumen de Etiquetas")
    result.append(create_title_separator("Resumen de Etiquetas"))
    result.append("")

    # Ordenar etiquetas por frecuencia (descendente) y luego alfabéticamente
    sorted_tags = sorted(tags.items(), key=lambda x: (-x[1], x[0]))

    for tag, count in sorted_tags:
        result.append(f"- **{tag}**: {count} {'entrada' if count == 1 else 'entradas'}")

    result.append("")

    return "\n".join(result)


def convert_jrnl_to_presenterm(
    data: Dict[str, Any],
    include_tags: bool = False,
    include_date: bool = False,
    include_time: bool = False,
    tags_position: str = "end",
) -> str:
    """
    Convierte los datos del JSON de jrnl a formato markdown para presenterm.
    """
    result = []

    # Header YAML
    result.append("---")
    result.append("options:")
    result.append("  implicit_slide_ends: true")
    result.append("  end_slide_shorthand: true")
    result.append("---")
    result.append("")

    # Si se incluye la hora, automáticamente se incluye la fecha
    if include_time:
        include_date = True

    # Procesar entradas
    entries = data.get("entries", [])

    # Resumen de etiquetas al inicio
    if include_tags and (tags_position and tags_position.lower() == "start"):
        tags_summary = create_tags_summary(data.get("tags", {}))
        if tags_summary:
            result.append(tags_summary)
            # if entries:  # Solo agregar separador si hay entradas
            #     result.append("---")
            #     result.append("")

    for i, entry in enumerate(entries):
        formatted_entry = format_entry(entry, include_date, include_time)
        result.append(formatted_entry)

        # Agregar separador entre entradas (excepto la última)
        # if i < len(entries) - 1:
        #     result.append("---")
        #     result.append("")

    # Resumen de etiquetas al final
    if include_tags and (tags_position is None or tags_position.lower() == "end"):
        tags_summary = create_tags_summary(data.get("tags", {}))
        if tags_summary:
            # if entries:  # Solo agregar separador si hay entradas
            #     result.append("---")
            #     result.append("")
            result.append(tags_summary)

    return "\n".join(result)


def main():
    parser = argparse.ArgumentParser(
        description="Convierte JSON exportado de jrnl a formato Markdown para presenterm"
    )
    parser.add_argument(
        "--tags", action="store_true", help="Incluir resumen de etiquetas"
    )
    parser.add_argument(
        "--date", action="store_true", help="Incluir fecha en las entradas"
    )
    parser.add_argument(
        "--time",
        action="store_true",
        help="Incluir hora en las entradas (automáticamente incluye fecha)",
    )
    parser.add_argument(
        "--tags-position",
        choices=["start", "end"],
        # default="end",
        help="Posición del resumen de etiquetas (start/end). Automáticamente activa --tags",
    )

    args = parser.parse_args()

    # Si se especifica tags-position, automáticamente activar tags
    include_tags = args.tags or (args.tags_position is not None)

    try:
        # Leer JSON desde stdin
        data = json.load(sys.stdin)

        # Convertir a markdown
        markdown_output = convert_jrnl_to_presenterm(
            data,
            include_tags=include_tags,
            include_date=args.date,
            include_time=args.time,
            tags_position=args.tags_position,
        )

        # Escribir a stdout
        print(markdown_output)

    except json.JSONDecodeError as e:
        print(f"Error al decodificar JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
