"""Gera os recursos visuais Android do Novva a partir da marca transparente.

Uso (na raiz do repositório):

    python scripts/generate_android_assets.py

Requer Pillow (`pip install pillow`). Gera:

- ícones legados (mipmap-*/ic_launcher.png e ic_launcher_round.png);
- foreground e monochrome do ícone adaptativo (drawable-*/);
- ícone pequeno de notificação (drawable-*/ic_stat_novva.png);
- logo da splash nativa, com o mesmo filtro de cor usado pela SplashPage Flutter;
- ícone 512 x 512 e feature graphic 1024 x 500 para a ficha da Google Play.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "logo_mark_transparent.png"
FONT_DIR = ROOT / "assets" / "fonts"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
PLAY = ROOT / "app_store" / "google_play"

DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}

WHITE = (255, 255, 255, 255)
SPLASH_BACKGROUND = (3, 25, 35, 255)  # 0xFF031923, igual à SplashPage.

# Mesma matriz do widget NovvaLogo (lib/core/widgets/novva_logo.dart).
SPLASH_MATRIX = (
    (1.0, 1.05, -0.63),
    (0.0, 3.1, -1.26),
    (0.0, 2.1, -0.26),
)


def load_logo() -> Image.Image:
    logo = Image.open(LOGO).convert("RGBA")
    return logo.crop(logo.getbbox())


def fit(logo: Image.Image, size: int) -> Image.Image:
    """Redimensiona mantendo a proporção para caber em size x size."""
    ratio = size / max(logo.size)
    target = (max(1, round(logo.width * ratio)), max(1, round(logo.height * ratio)))
    return logo.resize(target, Image.LANCZOS)


def centered(canvas_size: int, content: Image.Image, background=(0, 0, 0, 0)) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), background)
    offset = ((canvas_size - content.width) // 2, (canvas_size - content.height) // 2)
    canvas.alpha_composite(content, offset)
    return canvas


def silhouette(logo: Image.Image) -> Image.Image:
    """Versão branca com o alfa original (ícone de notificação/monochrome)."""
    alpha = logo.getchannel("A")
    white = Image.new("RGBA", logo.size, WHITE)
    white.putalpha(alpha)
    return white


def splash_colored(logo: Image.Image) -> Image.Image:
    r, g, b, a = logo.split()
    pixels = list(zip(r.getdata(), g.getdata(), b.getdata()))
    bands = []
    for row in SPLASH_MATRIX:
        values = [
            min(255, max(0, round(row[0] * pr + row[1] * pg + row[2] * pb)))
            for pr, pg, pb in pixels
        ]
        channel = Image.new("L", logo.size)
        channel.putdata(values)
        bands.append(channel)
    return Image.merge("RGBA", (*bands, a))


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius, fill=255)
    return mask


def circle_mask(size: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    return mask


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(f"  {path.relative_to(ROOT)}")


def legacy_icon(logo: Image.Image, size: int, round_icon: bool) -> Image.Image:
    base = centered(size, fit(logo, round(size * (0.62 if round_icon else 0.7))), WHITE)
    mask = circle_mask(size) if round_icon else rounded_mask(size, round(size * 0.18))
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(base, (0, 0), mask)
    return result


def generate_launcher(logo: Image.Image) -> None:
    print("Ícones do launcher")
    for name, scale in DENSITIES.items():
        legacy = round(48 * scale)
        save(legacy_icon(logo, legacy, False), RES / f"mipmap-{name}" / "ic_launcher.png")
        save(legacy_icon(logo, legacy, True), RES / f"mipmap-{name}" / "ic_launcher_round.png")

        # Adaptive icon: canvas de 108dp, zona segura de 66dp de diâmetro.
        adaptive = round(108 * scale)
        foreground = centered(adaptive, fit(logo, round(58 * scale)))
        save(foreground, RES / f"drawable-{name}" / "ic_launcher_foreground.png")
        monochrome = centered(adaptive, fit(silhouette(logo), round(54 * scale)))
        save(monochrome, RES / f"drawable-{name}" / "ic_launcher_monochrome.png")


def generate_notification_icon(logo: Image.Image) -> None:
    print("Ícone de notificação")
    for name, scale in DENSITIES.items():
        size = round(24 * scale)
        icon = centered(size, fit(silhouette(logo), round(20 * scale)))
        save(icon, RES / f"drawable-{name}" / "ic_stat_novva.png")


def generate_splash(logo: Image.Image) -> None:
    print("Splash nativa")
    colored = splash_colored(logo)
    for name, scale in DENSITIES.items():
        # Android < 12: bitmap centralizado de 92dp, como na SplashPage.
        save(fit(colored, round(92 * scale)), RES / f"drawable-{name}" / "splash_logo.png")
        # Android 12+: ícone sem fundo ocupa 288dp e é recortado em um círculo de 192dp.
        canvas = round(288 * scale)
        save(centered(canvas, fit(colored, round(92 * scale))), RES / f"drawable-{name}" / "splash_icon.png")


def generate_play_assets(logo: Image.Image) -> None:
    print("Recursos da Google Play")
    icon = centered(512, fit(logo, 360), WHITE)
    save(icon, PLAY / "icon-512.png")

    feature = Image.new("RGBA", (1024, 500), SPLASH_BACKGROUND)
    mark = fit(splash_colored(logo), 230)
    feature.alpha_composite(mark, (110, (500 - mark.height) // 2))
    draw = ImageDraw.Draw(feature)
    try:
        title_font = ImageFont.truetype(str(FONT_DIR / "Poppins-SemiBold.ttf"), 92)
        body_font = ImageFont.truetype(str(FONT_DIR / "Poppins-Regular.ttf"), 34)
    except OSError:
        title_font = body_font = ImageFont.load_default()
    draw.text((400, 150), "Novva", font=title_font, fill=(243, 248, 250))
    draw.text((404, 275), "Contabilidade médica", font=body_font, fill=(161, 179, 187))
    draw.text((404, 320), "na palma da mão", font=body_font, fill=(161, 179, 187))
    # Feature graphic não pode ter canal alfa.
    save(feature.convert("RGB"), PLAY / "feature-graphic-1024x500.png")


def main() -> None:
    logo = load_logo()
    generate_launcher(logo)
    generate_notification_icon(logo)
    generate_splash(logo)
    generate_play_assets(logo)
    print("Concluído.")


if __name__ == "__main__":
    main()
