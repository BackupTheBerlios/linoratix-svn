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

#include "disk.h"
#include "partition.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Disk::Disk(const PedDisk *disk)
    : disk_(ped_disk_duplicate(disk)) {
}

Disk& Disk::operator=(const Disk &disk) {
    if (this == &disk) {
        return *this;
    }
    disk_ = ped_disk_duplicate(disk.disk_);
    return *this;
}

const PedDisk* Disk::get_c_disk() const {
    return disk_;
}

/* ------ *
 * public *
 * ------ */

Disk::Disk(const Disk &disk)
    : disk_(ped_disk_duplicate(disk_)) {
}

Disk::Disk(const Device &device)
    : disk_(ped_disk_new(const_cast<PedDevice*>(device.get_c_device()))) {
}

Disk::Disk(const Device &device, DiskType &type)
    : disk_(ped_disk_new_fresh(const_cast<PedDevice*>(device.get_c_device()),
                               type.get_c_disktype())) {
}

DiskType& Disk::probe(Device &dev) throw (std::runtime_error) {
    PedDiskType *type_;
    type_ = ped_disk_probe(const_cast<PedDevice*>(dev.get_c_device()));
    if (!type_) {
        throw std::runtime_error("Could not probe device!");
    }
    try {
        return *(new DiskType(type_));
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

bool Disk::clobber(Device &device) {
    return (ped_disk_clobber(const_cast<PedDevice*>(device.get_c_device())));
}

bool Disk::clobber_exclude(Device &device, const DiskType &type) {
    return (ped_disk_clobber_exclude(const_cast<PedDevice*>(device.get_c_device()), type.get_c_disktype()));
}

bool Disk::commit() {
    return (ped_disk_commit(disk_));
}

bool Disk::commit_to_dev() {
    return (ped_disk_commit_to_dev(disk_));
}

bool Disk::commit_to_os() {
    return (ped_disk_commit_to_os(disk_));
}

bool Disk::check() {
    return (ped_disk_check(disk_));
}

void Disk::print() {
    return (ped_disk_print(disk_));
}

bool Disk::add_partition(const Partition &part,
                         const Constraint &constraint)
{
    return (ped_disk_add_partition(disk_, const_cast<PedPartition*>(part.get_c_partition()), constraint.get_c_constraint()));
}

bool Disk::remove_partition(const Partition &part) {
    return (ped_disk_remove_partition(disk_, const_cast<PedPartition*>(part.get_c_partition())));
}

bool Disk::delete_partition(const Partition &part) {
    return (ped_disk_delete_partition(disk_, const_cast<PedPartition*>(part.get_c_partition())));
}

bool Disk::delete_all() {
    return (ped_disk_delete_all(disk_));
}

bool Disk::set_partition_geom(const Partition &part,
                              const Constraint &constraint,
                              const Sector start,
                              const Sector end)
{
    return (ped_disk_set_partition_geom(disk_, const_cast<PedPartition*>(part.get_c_partition()), constraint.get_c_constraint(), start, end));
}

bool Disk::maximize_partition(const Partition &part,
                              const Constraint &constraint)
{
    return (ped_disk_maximize_partition(disk_, const_cast<PedPartition*>(part.get_c_partition()), constraint.get_c_constraint()));
}

Geometry& Disk::get_max_partition_geometry(Partition &part,
                                           Constraint &constraint)
                                           throw (std::runtime_error)
{
    PedGeometry *geom_;
    geom_ = ped_disk_get_max_partition_geometry(disk_,
            const_cast<PedPartition*>(part.get_c_partition()),
            const_cast<PedConstraint*>(constraint.get_c_constraint()));
    if (!geom_) {
        throw std::runtime_error("An error has occured!");
    }
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

bool Disk::minimize_extended_partition() {
    return (ped_disk_minimize_extended_partition(disk_));
}

Partition& Disk::get_next_partition(Partition &part) throw (std::runtime_error) {
    PedPartition *part_;
    part_ = ped_disk_next_partition(disk_, part.get_c_partition());
    if (!part_) {
        throw std::runtime_error("No further partitions found!");
    }
    try {
        return *(new Partition(part_));
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

Partition& Disk::get_partition(int num) throw (std::runtime_error) {
    PedPartition *part_;
    part_ = ped_disk_get_partition(disk_, num);
    if (!part_) {
        throw std::runtime_error("No such partition found!");
    }
    try {
        return *(new Partition(part_));
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

Partition& Disk::get_partition_by_sector(Sector sect) throw (std::runtime_error) {
    PedPartition *part_;
    part_ = ped_disk_get_partition_by_sector(disk_, sect);
    if (!part_) {
        throw std::runtime_error("No such partition found!");
    }
    try {
        return *(new Partition(part_));
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

Partition& Disk::get_extended_partition() throw (std::runtime_error) {
    PedPartition *part_;
    part_ = ped_disk_extended_partition(disk_);
    if (!part_) {
        throw std::runtime_error("No extended partition could be found!");
    }
    try {
        return *(new Partition(part_));
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

int Disk::get_primary_partition_count() {
    return (ped_disk_get_primary_partition_count(disk_));
}

int Disk::get_max_primary_partition_count() {
    return (ped_disk_get_max_primary_partition_count(disk_));
}

int Disk::get_last_partition_num() {
    return (ped_disk_get_last_partition_num(disk_));
}

const Device& Disk::get_device() const {
    Device *dev;
    try {
        dev = new Device(disk_->dev);
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
    return *dev;
}

const DiskType& Disk::get_disktype() const {
    DiskType *disk_type;
    try {
        disk_type = new DiskType(disk_->type);
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
    return *disk_type;
}

Disk::~Disk() {
    if (0 != disk_) {
        ped_disk_destroy(disk_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
