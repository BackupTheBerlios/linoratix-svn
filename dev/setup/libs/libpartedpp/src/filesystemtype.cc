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

#include "filesystemtype.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

FileSystemType::FileSystemType() {
}

FileSystemType::FileSystemType(const PedFileSystemType *fst)
    : fs_type_(ped_file_system_type_get(fst->name)) {
}

FileSystemType::FileSystemType(const FileSystemType &fst)
    : fs_type_(ped_file_system_type_get(fst.fs_type_->name)) {
}

FileSystemType& FileSystemType::operator=(const FileSystemType &fst) {
    if (this == &fst) {
        return *this;
    }
    fs_type_ = ped_file_system_type_get(fst.fs_type_->name);
    return *this;
}

const PedFileSystemType* FileSystemType::get_c_file_system_type() const {
    return fs_type_;
}

/* ------ *
 * public *
 * ------ */

FileSystemType::FileSystemType(std::string &name)
    : fs_type_(ped_file_system_type_get(name.c_str())) {
}

FileSystemType& FileSystemType::get_next() throw (std::runtime_error) {
    PedFileSystemType *fst;
    fst = ped_file_system_type_get_next(fs_type_);
    if (!fst) {
        throw std::runtime_error("No further filesystem types found!");
    }
    try {
        return *(new FileSystemType(fst));
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

const std::string& FileSystemType::get_name() const {
    std::string *type;
    try {
        type = new std::string(fs_type_->name);
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
    return *type;
}

FileSystemType::~FileSystemType() {
}

/* vim: set tabstop=4 et shiftwidth=4: */
