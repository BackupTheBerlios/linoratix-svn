/*
 *  Copyright (C) 2003 Christian Zeller
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "timerhandler.h"

using namespace Ped;

static void c_handler_func(PedTimer* timer, void* context) {
    struct THHelpStruct *data;

    data = static_cast<THHelpStruct*>(context);
    data->phandler->invoke();
}

TimerHandler::TimerHandler() {
    // Create help-struct
    help_struct             = new THHelpStruct;
    help_struct->phandler   = this;

    c_handler_              = c_handler_func;
}

TimerHandler::~TimerHandler() {
    // Destroy help-struct
    if (help_struct != 0)
        delete help_struct;
}

THHelpStruct* TimerHandler::get_help_struct() {
    return help_struct;
}

PedTimerHandler* TimerHandler::get_c_handler() {
    return c_handler_;
}

/* vim: set tabstop=4 et shiftwidth=4: */
