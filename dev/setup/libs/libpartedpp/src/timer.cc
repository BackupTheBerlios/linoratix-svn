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

#include "timer.h"
#include "timerhandler.h"

using namespace Ped;

Timer::Timer(TimerHandler* handler) {
    nested   = false;
    handler_ = handler;
    timer_   = ped_timer_new(handler->get_c_handler(),
                             handler->get_help_struct());
}

Timer::Timer(Timer* parent, float nest_frac) {
    nested = true;
    timer_ = ped_timer_new_nested(parent->get_c_timer(), nest_frac);
}

PedTimer* Timer::get_c_timer() const {
    return timer_;
}

void Timer::touch() {
    ped_timer_touch(timer_);
}

void Timer::reset() {
    ped_timer_reset(timer_);
}

void Timer::update(float new_frac) {
    ped_timer_update(timer_, new_frac);
}

void Timer::set_state_name(const std::string &state_name) {
    ped_timer_set_state_name(timer_, state_name.c_str());
}

Timer::~Timer() {
    if (nested) {
        ped_timer_destroy_nested(timer_);
    } else {
        ped_timer_destroy(timer_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
