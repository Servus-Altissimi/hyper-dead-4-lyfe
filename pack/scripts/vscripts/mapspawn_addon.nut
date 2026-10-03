if (!("HD4L" in getroottable()))
	IncludeScript("hd4l_core", getroottable());
if ("HD4L" in getroottable())
	try { ::HD4L.LoadParts(); }
	catch (e) { printl("[HD4L] LoadParts at map spawn failed: " + e); }
