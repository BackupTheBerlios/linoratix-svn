/*
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

#include "geometry.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Geometry::Geometry() {
}

Geometry::Geometry(const PedGeometry *geom)
    : geom_(ped_geometry_duplicate(geom)) {
}

Geometry::Geometry(const Geometry &geom)
    : geom_(ped_geometry_duplicate(geom.geom_)) {
}

Geometry& Geometry::operator=(const Geometry &geom) {
    if (this == &geom) {
        return *this;
    }
    geom_  = ped_geometry_duplicate(geom.geom_);
    return *this;
}

const PedGeometry* Geometry::get_c_geometry() const {
    return geom_;
}

/* ------ *
 * public *
 * ------ */

Geometry::Geometry(Device &dev, Sector start, Sector length) {
    geom_ = ped_geometry_new(dev.device_, start, length);
    if (geom_) {
        ped_geometry_init(geom_, dev.device_, start, length);
    }
}

Geometry::Geometry(Geometry &geom)
    : geom_(ped_geometry_duplicate(geom.geom_)) {
}

Geometry::Geometry(const Geometry &a, const Geometry &b)
    : geom_(ped_geometry_intersect(a.geom_, b.geom_)) {
}

void Geometry::set(Sector start, Sector length) {
    ped_geometry_set(geom_, start, length);
}

void Geometry::set_start(Sector start) {
    ped_geometry_set_start(geom_, start);
}

void Geometry::set_end(Sector end) {
    ped_geometry_set_end(geom_, end);
}

bool Geometry::test_overlap(Geometry &a, Geometry &b) {
    return (ped_geometry_test_overlap(a.geom_, b.geom_));
}

bool Geometry::test_inside(Geometry &a, Geometry &b) {
    return (ped_geometry_test_inside(a.geom_, b.geom_));
}

bool Geometry::test_equal(Geometry &a, Geometry &b) {
    return (ped_geometry_test_equal(a.geom_, b.geom_));
}

bool Geometry::test_sector_inside(Sector sect) {
    return (ped_geometry_test_sector_inside(geom_, sect));
}

bool Geometry::read(void *buffer, Sector offset, Sector count) {
    return (ped_geometry_read(geom_, buffer, offset, count));
}

bool Geometry::write(void *buffer, Sector offset, Sector count) {
    return (ped_geometry_write(geom_, buffer, offset, count));
}

Sector Geometry::check(void *buffer, Sector buffer_size, Sector offset,
                       Sector granularity, Sector count, Timer& timer) {
    return (ped_geometry_check(geom_, buffer, buffer_size, offset,
                               granularity, count, timer.get_c_timer()));
}

bool Geometry::sync() {
    return (ped_geometry_sync(geom_));
}

Sector Geometry::map(Geometry &dst, Geometry &src, Sector sector) {
    return (ped_geometry_map(dst.geom_, src.geom_, sector));
}

const Device& Geometry::get_device() const {
    Device *device;
    try {
        device = new Device(geom_->dev);
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        delete device;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
    }
    return *device;
}

const Sector Geometry::get_start() const {
    return (geom_->start);
}

const Sector Geometry::get_length() const {
    return (geom_->length);
}

const Sector Geometry::get_end() const {
    return (geom_->end);
}

Geometry::~Geometry() {
    if (geom_) {
        ped_geometry_destroy(geom_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
