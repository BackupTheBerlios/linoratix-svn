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

#include "filesystem.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

FileSystem::FileSystem() {
}

FileSystem::FileSystem(const PedFileSystem *fs)
    : fs_(ped_file_system_copy(const_cast<PedFileSystem*>(fs),
                               fs->geom, NULL)) { // FIXME
}

FileSystem::FileSystem(const FileSystem &fs)
    : fs_(ped_file_system_copy(fs.fs_, fs.fs_->geom, NULL)) { // FIXME
}

FileSystem& FileSystem::operator=(const FileSystem &fs) {
    if (this == &fs) {
        return *this;
    }
    fs_ = (ped_file_system_copy(fs.fs_, fs.fs_->geom, NULL)); // FIXME
    return *this;
}

const PedFileSystem* FileSystem::get_c_filesystem() const {
    return fs_;
}

/* ------ *
 * public *
 * ------ */

FileSystem::FileSystem(Geometry &geom, FileSystemType &type, Timer &timer)
    : fs_(ped_file_system_create(const_cast<PedGeometry*>(geom.get_c_geometry()), type.get_c_file_system_type(), timer.get_c_timer())) {
}

FileSystem::FileSystem(Geometry &geom, Timer &timer)
    : fs_(ped_file_system_copy(fs_,
                               const_cast<PedGeometry*>(geom.get_c_geometry()),
                               timer.get_c_timer())) {
}

FileSystemType& FileSystem::probe(Geometry &geom) throw (std::runtime_error) {
    PedFileSystemType *fs_type_;
    fs_type_ = (ped_file_system_probe(const_cast<PedGeometry*>(geom.get_c_geometry())));
    if (!fs_type_) {
        throw std::runtime_error("No filesystem found!");
    }
    try {
        return *(new FileSystemType(fs_type_));
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

Geometry& FileSystem::probe_specific(const FileSystemType &type,
                                     Geometry &geom) {
    geom.geom_ = (ped_file_system_probe_specific(type.get_c_file_system_type(),
                  const_cast<PedGeometry*>(geom.get_c_geometry())));
    return geom;
}

bool FileSystem::clobber(Geometry &geom) {
    return (ped_file_system_clobber(const_cast<PedGeometry*>(geom.get_c_geometry())));
}

FileSystem& FileSystem::open(Geometry &geom) throw (std::runtime_error) {
    PedFileSystem *fs_;
    fs_ = ped_file_system_open(const_cast<PedGeometry*>(geom.get_c_geometry()));
    if (!fs_) {
        throw std::runtime_error("Couldn't open filesystem!");
    }
    try {
        return *(new FileSystem(fs_));
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

bool FileSystem::close() {
    return (ped_file_system_close(fs_));
}

bool FileSystem::check(Timer &timer) {
    return (ped_file_system_check(fs_, timer.get_c_timer()));
}

bool FileSystem::resize(Geometry &geom, Timer &timer) {
    return (ped_file_system_resize(fs_, const_cast<PedGeometry*>(geom.get_c_geometry()), timer.get_c_timer()));
}


Constraint& FileSystem::get_create_constraint(const FileSystemType &fs_type,
                                              const Device &dev) throw (std::runtime_error) {
    PedConstraint *constr_;
    constr_ = ped_file_system_get_create_constraint(fs_type.get_c_file_system_type(), dev.get_c_device());
    if (!constr_) {
        throw std::runtime_error("Couldn't get costraint!");
    }
    try {
        return *(new Constraint(constr_));
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

Constraint& FileSystem::get_resize_constraint() throw (std::runtime_error) {
    PedConstraint *constr_;
    constr_ = ped_file_system_get_resize_constraint(fs_);
    if (!constr_) {
        throw std::runtime_error("Couldn't get constraint!");
    }
    try {
        return *(new Constraint(constr_));
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

Constraint& FileSystem::get_copy_constraint(const Device &dev) throw (std::runtime_error) {
    PedConstraint *constr_;
    constr_ = ped_file_system_get_copy_constraint(fs_, dev.get_c_device());
    if (!constr_) {
        throw std::runtime_error("Couldn't get constraint!");
    }
    try {
        return *(new Constraint(constr_));
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

const FileSystemType& FileSystem::get_filesystem_type() const {
    FileSystemType *fst;
    try {
        fst = new FileSystemType(fs_->type);
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
    return *fst;
}

const Geometry& FileSystem::get_geometry() const {
    Geometry *geom;
    try {
        geom = new Geometry(fs_->geom);
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
        throw;
    }
    catch (Exception &e) {
        std::cerr << e.what();
        throw;
    }
    catch (...) {
        std::cerr << "An unkown error has occured!" << std::endl;
        throw;
    }
    return *geom;
}

const bool FileSystem::is_checked() const {
    return (fs_->checked);
}

FileSystem::~FileSystem() {
}

/* vim: set tabstop=4 et shiftwidth=4: */
