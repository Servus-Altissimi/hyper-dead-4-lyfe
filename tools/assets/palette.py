BONE = (225, 215, 195)
AMBER = (255, 176, 60)
BLOOD = (215, 45, 35)
EMBER = (255, 120, 50)
ASH = (130, 122, 108)
SHADE = (46, 40, 36)


def drawcolor(rgb, alpha=255):
    return " ".join(str(c) for c in (*rgb, alpha))
