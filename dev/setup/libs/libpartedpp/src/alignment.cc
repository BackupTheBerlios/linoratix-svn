/*
 *  Copyright (C) 2003 Christian Zeller
 *  Copyright (C) 2003 Christian Meyer
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

#include "alignment.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Alignment::Alignment() {
}

Alignment::Alignment(const PedAlignment *align)
    : alignment_(ped_alignment_duplicate(align)) {
}

Alignment& Alignment::operator=(const Alignment &align) {
    if (this == &align) {
        return *this;
    }
    alignment_ = ped_alignment_duplicate(align.get_c_alignment());
    return *this;
}

const PedAlignment* Alignment::get_c_alignment() const {
    return alignment_;
}

/* ------ *
 * public *
 * ------ */

Alignment::Alignment(Sector offset, Sector grain_size)
    : alignment_(ped_alignment_new(offset, grain_size)) {
    ped_alignment_init(alignment_, offset, grain_size);
}

Alignment::Alignment(const Alignment &align)
    : alignment_(ped_alignment_duplicate(align.get_c_alignment())) {
}

Alignment::Alignment(const Alignment& a, const Alignment &b)
    : alignment_(ped_alignment_intersect(a.get_c_alignment(),
                                         b.get_c_alignment())) {
}

Sector Alignment::align_up( Geometry& geom, Sector sector) {
    return (ped_alignment_align_up(alignment_, geom.get_c_geometry(), sector));
}

Sector Alignment::align_down( Geometry& geom, Sector sector) {
    return (ped_alignment_align_down(alignment_, geom.get_c_geometry(), sector));
}

Sector Alignment::align_nearest( Geometry& geom, Sector sector) {
    return (ped_alignment_is_aligned(alignment_, geom.get_c_geometry(), sector));
}

bool Alignment::is_aligned( Geometry& geom, Sector sector) {
    return (ped_alignment_is_aligned(alignment_, geom.get_c_geometry(), sector));
}

Alignment::~Alignment() {
    if (alignment_) {
        ped_alignment_destroy(alignment_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
