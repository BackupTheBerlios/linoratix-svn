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

#include "constraint.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Constraint::Constraint() {
}

Constraint::Constraint(const PedConstraint *constr)
    : constraint_(ped_constraint_duplicate(constr)) {
}

Constraint& Constraint::operator=(const Constraint &constr) {
    if (this == &constr) {
        return *this;
    }
    constraint_ = ped_constraint_duplicate(constr.get_c_constraint());
    return *this;
}

const PedConstraint* Constraint::get_c_constraint() const {
    return constraint_;
}

/* ------ *
 * public *
 * ------ */

Constraint::Constraint(Alignment& start_align, Alignment& end_align,
                       Geometry& start_range, Geometry& end_range,
                       Sector min_size, Sector max_size)
    : constraint_(ped_constraint_new (start_align.get_c_alignment(),
                                      end_align.get_c_alignment(),
                                      start_range.get_c_geometry(),
                                      end_range.get_c_geometry(),
                                      min_size, max_size))
{

    ped_constraint_init (constraint_,
                         start_align.get_c_alignment(),
                         end_align.get_c_alignment(),
                         start_range.get_c_geometry(),
                         end_range.get_c_geometry(),
                         min_size,
                         max_size);
}

Constraint::Constraint(Geometry& min, Geometry& max)
    : constraint_(ped_constraint_new_from_min_max(min.get_c_geometry(),
                                                  max.get_c_geometry())) {
}

Constraint::Constraint(Geometry& minmax, bool isMin) {
    if (isMin) {
        constraint_ = ped_constraint_new_from_min(minmax.get_c_geometry());
    } else {
        constraint_ = ped_constraint_new_from_max(minmax.get_c_geometry());
    }
}

Constraint::Constraint(const Constraint &constr)
    : constraint_(ped_constraint_duplicate(constr.get_c_constraint())) {
}

Constraint::Constraint(const Constraint &a, const Constraint &b)
    : constraint_(ped_constraint_intersect(a.get_c_constraint(),
                                           b.get_c_constraint())) {
}

Geometry& Constraint::solve_max() {
    PedGeometry *geom_;
    geom_ = ped_constraint_solve_max(constraint_);
    try {
        return *(new Geometry(geom_));
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
        throw;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        throw;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
        throw;
    }
}

Geometry& Constraint::solve_nearest(Geometry& geom) {
    PedGeometry *geom_;
    geom_ = ped_constraint_solve_nearest(constraint_, geom.get_c_geometry());
    try {
        return *(new Geometry(geom_));
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
        throw;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        throw;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
        throw;
    }
}

bool Constraint::is_solution(Geometry& geom) {
    return (ped_constraint_is_solution(constraint_, geom.get_c_geometry()));
}

Constraint::~Constraint() {
    if (constraint_) {
        ped_constraint_done(constraint_);
        ped_constraint_destroy(constraint_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
