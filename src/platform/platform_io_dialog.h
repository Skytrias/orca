/************************************************************/ /**
*
*	@file: platform_io_dialog.h
*	@author: Martin Fouilleul
*	@date: 01/09/2023
*
*****************************************************************/
#ifndef __PLATFORM_IO_DIALOG_H_
#define __PLATFORM_IO_DIALOG_H_

#include "platform_io.h"
#include "app/app.h"

typedef struct oc_file_open_with_dialog_elt
{
    oc_list_elt listElt;
    oc_file file;
} oc_file_open_with_dialog_elt;

typedef struct oc_file_open_with_dialog_result
{
    oc_file_dialog_button button;
    oc_file file;
    oc_list selection;
} oc_file_open_with_dialog_result;

ORCA_API oc_file_open_with_dialog_result oc_file_open_with_dialog(oc_arena* arena, oc_file_access rights, oc_file_open_flags flags, oc_file_dialog_desc* desc);

#endif //__PLATFORM_IO_DIALOG_H_