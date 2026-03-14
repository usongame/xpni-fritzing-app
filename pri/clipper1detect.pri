# Copyright (c) 2023 Fritzing GmbH

message("Using fritzing Clipper 1 detect script.")

unix {
    message("including Clipper1 library on linux or mac")

    exists($$absolute_path($$_PRO_FILE_PWD_/libs/Clipper1)) {
	            CLIPPER1 = $$absolute_path($$_PRO_FILE_PWD_/libs/Clipper1/6.4.2)
				message("found Clipper1 in $${CLIPPER1}")
			}
}

win32 {
    message("including Clipper1 library on windows")

    exists($$absolute_path($$_PRO_FILE_PWD_/libs/Clipper1)) {
        CLIPPER1 = $$absolute_path($$_PRO_FILE_PWD_/libs/Clipper1/6.4.2)
                    message("found Clipper1 in $${CLIPPER1}")
            }
}

message("including $$absolute_path($${CLIPPER1})")
INCLUDEPATH += $$absolute_path($${CLIPPER1})

# For Clipper1 library, we just need to include the header, no library to link since it's a header-only or single-file library
