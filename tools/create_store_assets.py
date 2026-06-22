from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "store-assets"
FEATURE_SIZE = (1024, 500)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def fit(image: Image.Image, max_size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    scale = min(max_size[0] / image.width, max_size[1] / image.height)
    return image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)


def load_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "Assets" / "Fonts" / "LuckiestGuy-Regular.ttf"), size)


def draw_centered_text(draw: ImageDraw.ImageDraw, text: str, y: int, font: ImageFont.FreeTypeFont) -> None:
    bbox = draw.textbbox((0, 0), text, font=font, stroke_width=4)
    x = (FEATURE_SIZE[0] - (bbox[2] - bbox[0])) // 2
    draw.text((x, y), text, font=font, fill=(255, 248, 176), stroke_width=4, stroke_fill=(80, 49, 12))


def create_feature_graphic() -> Path:
    background_art = cover(Image.open(ROOT / "Assets" / "Environment" / "background_landscape.png"), FEATURE_SIZE)
    sky = Image.new("RGBA", FEATURE_SIZE, (0, 0, 0, 0))
    sky_draw = ImageDraw.Draw(sky)
    for y in range(FEATURE_SIZE[1]):
        ratio = y / FEATURE_SIZE[1]
        color = (
            round(69 + 84 * ratio),
            round(203 + 36 * ratio),
            round(245 - 61 * ratio),
            255,
        )
        sky_draw.line((0, y, FEATURE_SIZE[0], y), fill=color)
    background = Image.alpha_composite(sky, background_art).filter(ImageFilter.GaussianBlur(radius=1.2))

    overlay = Image.new("RGBA", FEATURE_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle((38, 36, 986, 464), radius=36, fill=(255, 205, 74, 58), outline=(255, 255, 255, 120), width=4)
    draw.rectangle((0, 0, FEATURE_SIZE[0], FEATURE_SIZE[1]), fill=(0, 0, 0, 40))
    canvas = Image.alpha_composite(background, overlay)

    logo = fit(Image.open(ROOT / "Assets" / "UI" / "logo.png"), (560, 245))
    logo_shadow = Image.new("RGBA", logo.size, (0, 0, 0, 0))
    logo_shadow.alpha_composite(logo)
    logo_shadow = logo_shadow.filter(ImageFilter.GaussianBlur(radius=8))
    logo_x = (FEATURE_SIZE[0] - logo.width) // 2
    canvas.alpha_composite(logo_shadow, (logo_x + 5, 96 + 8))
    canvas.alpha_composite(logo, (logo_x, 96))

    draw = ImageDraw.Draw(canvas)
    draw_centered_text(draw, "Catch Eggs. Dodge Trouble.", 344, load_font(48))
    draw_centered_text(draw, "A fast arcade game for quick high-score runs", 405, load_font(28))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / "feature-graphic-1024x500.png"
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


if __name__ == "__main__":
    print(create_feature_graphic())
