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

#include "device.h"

using namespace Ped;

/* ------- *
 * private *
 * ------- */

Device::Device(const PedDevice *device)
    : device_(ped_device_get(device->path)) {
}

Device::Device(const Device &device)
    : device_(ped_device_get(device.device_->path)) {
}

Device& Device::operator=(const Device &device) {
    if (this == &device) {
       return *this;
    }
    device_ = ped_device_get(device.device_->path);
    return *this;
}

const PedDevice* Device::get_c_device() const {
    return device_;
}

/* ------ *
 * public *
 * ------ */

Device::Device() throw (std::runtime_error) {
    ped_device_probe_all();
    device_ = ped_device_get_next(device_);
    if (!device_) {
        throw std::runtime_error("No further devices found!");
    }
}

Device::Device(const std::string& name) throw (std::runtime_error) {
    device_ = ped_device_get(name.c_str());
    if (!device_) {
        throw std::runtime_error("You were trying to access a device which does NOT exist!");
    }
}

Device& Device::get_next() throw (std::runtime_error) {
    PedDevice *device;
    device = ped_device_get_next(device_);
    if (!device) {
        throw std::runtime_error("No further devices found!");
    }
    try {
        return *(new Device(device));
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

bool Device::is_busy() {
    return (ped_device_is_busy(device_));
}

bool Device::open() {
    return (ped_device_open(device_));
}

bool Device::close() {
    return (ped_device_close(device_));
}

bool Device::begin_external_access() {
    return (ped_device_begin_external_access(device_));
}

bool Device::end_external_access() {
    return (ped_device_end_external_access(device_));
}

const std::string Device::get_model() const {
    return (std::string(device_->model));
}

const std::string Device::get_path() const {
    return (std::string(device_->path));
}

const Device::DeviceType Device::get_type() const {
    return (static_cast<DeviceType>(device_->type));
}

const Sector Device::get_length() const {
    return (device_->length);
}

Device::~Device() {
    if (0 != device_) {
        ped_device_destroy(device_);
    }
}

/* vim: set tabstop=4 et shiftwidth=4: */
