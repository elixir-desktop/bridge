-record(wx, {id, obj, userData, event}).
-record(wxCommand, {type, cmdString, commandInt, extraLong}).
-record(wxClose, {type}).
-record(wxMenu, {type, menuId, menu}).

-define(wxDEFAULT_FRAME_STYLE, 2).
-define(wxEXPAND, 4).
-define(wxHORIZONTAL, 8).
-define(wxICON_ERROR, 16).
-define(wxICON_INFORMATION, 32).
-define(wxICON_QUESTION, 64).
-define(wxICON_WARNING, 128).
-define(wxID_ANY, 256).
-define(wxITEM_CHECK, 512).
-define(wxITEM_NORMAL, 1024).
-define(wxITEM_RADIO, 2048).
-define(wxITEM_SEPARATOR, 4096).
-define(wxMAJOR_VERSION, 8192).
-define(wxMINOR_VERSION, 16384).
-define(wxRELEASE_NUMBER, 32768).
-define(wxIMAGE_QUALITY_NEAREST, wxIMAGE_QUALITY_NEAREST).
-define(wxIMAGE_QUALITY_BILINEAR, wxIMAGE_QUALITY_BILINEAR).
-define(wxIMAGE_QUALITY_BICUBIC, wxIMAGE_QUALITY_BICUBIC).
-define(wxIMAGE_QUALITY_BOX_AVERAGE, wxIMAGE_QUALITY_BOX_AVERAGE).
-define(wxIMAGE_QUALITY_NORMAL, wxIMAGE_QUALITY_NORMAL).
-define(wxIMAGE_QUALITY_HIGH, wxIMAGE_QUALITY_HIGH).
-define(wxID_EXIT, wxID_EXIT).
-define(wxNO_BORDER, wxNO_BORDER).
