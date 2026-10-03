import re

from ...util import game_file, strip_kv_comments, workdir, write

FONTS = {"HD4LNumbers": 34, "HD4LAmmo": 18, "HD4LLabel": 12, "HD4LSmall": 10}


def build(out):
    with workdir() as tmp:
        text = game_file("resource/clientscheme.res", tmp, sources=("left4dead2",)).read_text(encoding="utf-8", errors="replace")
    text = text.replace("\r", "")
    fonts = "".join('\t\t%s\n\t\t{\n\t\t\t"1"\n\t\t\t{\n\t\t\t\t"name"\t\t"Poppins"\n\t\t\t\t"tall"\t\t"%d"\n'
                    '\t\t\t\t"weight"\t"700"\n\t\t\t\t"antialias"\t"1"\n\t\t\t}\n\t\t}\n' % (name, tall) for name, tall in FONTS.items())
    text, n = re.subn(r'(\n\tFonts\s*\n\t\{\n)', lambda m: m.group(1) + fonts, text, count=1)
    assert n == 1, "Fonts block"
    text, n = re.subn(r'(\n\t\t"6"\s+"resource/Stubble-Bold.vfont"[^\n]*\n)', r'\1\t\t"7"\t\t"resource/Poppins-700.ttf"\n', text, count=1)
    assert n == 1, "CustomFontFiles"
    write(out / "parts/hyper-feedback/addon/resource/clientscheme.res", strip_kv_comments(text))
    print("clientscheme.res: stock plus the Poppins fonts")
