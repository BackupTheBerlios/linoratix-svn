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

#include "partition.h"
#include "disk.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Partition::Partition() {
}

Partition::Partition(const PedPartition *part)
    : part_(ped_partition_new(part->disk, part->type, part->fs_type,
                              part->geom.start, part->geom.end)) {
}

Partition::Partition(const Partition &partition)
    : part_(ped_partition_new(partition.part_->disk,
                              partition.part_->type,
                              partition.part_->fs_type,
                              partition.part_->geom.start,
                              partition.part_->geom.end)) {
}

Partition& Partition::operator=(const Partition &partition) {
    if (this == &partition) {
          return *this;
    }
    part_ = ped_partition_new(partition.part_->disk,
                              partition.part_->type,
                              partition.part_->fs_type,
                              partition.part_->geom.start,
                              partition.part_->geom.end);
    return *this;
}

const PedPartition* Partition::get_c_partition() const {
    return part_;
}

/* ------ *
 * public *
 * ------ */

Partition::Partition(Disk &disk, PartitionType part_type,
                     const FileSystemType &fs_type,
                     Sector start, Sector end)
    : part_(ped_partition_new(disk.get_c_disk(), static_cast<PedPartitionType>(part_type), fs_type.get_c_file_system_type(), start, end)) {
}

bool Partition::is_active() {
    return (ped_partition_is_active(part_));
}

bool Partition::set_flag(PartitionFlag flag, int state) {
    return (ped_partition_set_flag(part_, static_cast<PedPartitionFlag>(flag), state));
}

bool Partition::get_flag(PartitionFlag flag) {
    return (ped_partition_get_flag(part_, static_cast<PedPartitionFlag>(flag)));
}

bool Partition::is_flag_available(PartitionFlag flag) {
    return (ped_partition_is_flag_available(part_, static_cast<PedPartitionFlag>(flag)));
}


bool Partition::set_system(FileSystemType &fs_type) {
    return (ped_partition_set_system(part_, fs_type.get_c_file_system_type()));
}


bool Partition::set_name(std::string &name) {
    return (ped_partition_set_name(part_, name.c_str()));
}

const std::string Partition::get_name() {
    return (std::string(ped_partition_get_name(part_)));
}

std::string Partition::get_path() {
    return (std::string(ped_partition_get_path(part_)));
}

bool Partition::is_busy() {
    return (ped_partition_is_busy(part_));
}

const std::string Partition::get_type_name(PartitionType part_type) {
    return (std::string(ped_partition_type_get_name(static_cast<PedPartitionType>(part_type))));
}

const std::string Partition::flag_get_name(PartitionFlag flag) {
    return (std::string(ped_partition_flag_get_name(static_cast<PedPartitionFlag>(flag))));
}

Partition::PartitionFlag Partition::get_flag_by_name(const std::string &name) {
    return (static_cast<PartitionFlag>(ped_partition_flag_get_by_name(name.c_str())));
}

Partition::PartitionFlag Partition::get_next_flag(PartitionFlag flag) {
    return (static_cast<PartitionFlag>(ped_partition_flag_next((PedPartitionFlag)flag)));
}

const Disk& Partition::get_disk() const {
    Disk *disk;
    try {
        disk = new Disk(part_->disk);
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        delete disk;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
        delete disk;
    }
    return *disk;
}

const Geometry& Partition::get_geometry() const {
    Geometry *geom;
    try {
        geom = new Geometry(&(part_->geom));
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        delete geom;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
    }
    return *geom;
}

const int Partition::get_num() const {
    return (part_->num);
}

const Partition::PartitionType Partition::get_partition_type() const {
    return (static_cast<PartitionType>(part_->type));
}

const FileSystemType& Partition::get_file_system_type() const throw (std::runtime_error) {
    if (!part_->fs_type) {
        throw std::runtime_error("Filesystem type is NULL!");
    }
    FileSystemType *fs_type;
    try {
        fs_type = new FileSystemType(part_->fs_type);
    }
    catch (std::bad_alloc &e) {
        std::cerr << e.what() << std::endl;
    }
    catch (Exception &e) {
        std::cerr << e.what() << std::endl;
        delete fs_type;
    }
    catch (...) {
        std::cerr << "An unknown error has occured!" << std::endl;
        delete fs_type;
    }
    return *fs_type;
}

/*
const Partition& Partition::get_ext_partition() const {
    return part_list;
}
*/

Partition::~Partition() {
    if (0 != part_) {
        ped_partition_destroy(part_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
