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

#include "disktype.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

DiskType::DiskType() {
}

DiskType::DiskType(const PedDiskType* type)
    : type_(ped_disk_type_get(type->name)) {
}

DiskType::DiskType(const DiskType &type)
    : type_(ped_disk_type_get(type.type_->name)) {
}

DiskType& DiskType::operator=(const DiskType &type) {
    if (this == &type) {
        return *this;
    }
    type_     = ped_disk_type_get(type.type_->name);
    return *this;
}

const PedDiskType* DiskType::get_c_disktype() const {
    return type_;
}

/* ------ *
 * public *
 * ------ */

DiskType::DiskType(const std::string &name)
    : type_(ped_disk_type_get(name.c_str())) {
}

DiskType& DiskType::get_next() throw (std::runtime_error) {
    PedDiskType *disk_type;
    disk_type = ped_disk_type_get_next(type_);
    if (!disk_type) {
        throw std::runtime_error("No further disk type!");
    }
    try {
        return *(new DiskType(disk_type));
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
        std::cerr << "An unkown error has occured!" << std::endl;
        throw;
    }
}

bool DiskType::check_feature(DiskType::DiskTypeFeature &feature) {
    return (ped_disk_type_check_feature(type_,
                static_cast<PedDiskTypeFeature>(feature)));
}

const std::string& DiskType::get_name() const {
    std::string *name;
    try {
        name = new std::string(type_->name);
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
        std::cerr << "An unkown error has occured!" << std::endl;
        throw;
    }
    return *name;
}

DiskType::~DiskType() {
}

/* vim: set tabstop=4 et shiftwidth=4: */
