if (!("HD4L" in getroottable()))
	IncludeScript("hd4l_core", getroottable());
::HD4L.LoadParts();

MutationOptions <- {
	weaponsToConvert = ::HD4L.ConvertTable(::HD4L.WeaponsCoop)

	function ConvertWeaponSpawn(classname) {
		return ::HD4L.ConvertWeapon(classname, ::HD4L.WeaponsCoop);
	}
}

MutationState <- {
}

