#ifndef PED_DEVICE_H
#define PED_DEVICE_H

#include <parted/parted.h>
#include <iostream>
#include <stdexcept>
#include <string>
#include "exception.h"

namespace Ped {

    typedef long long Sector;

    /**
     * The device class is basically what you always need.
     * It accesses all block devices which are installed in the computer.
     */
    class Device {

#ifndef DOXYGEN_SHOULD_SKIP_THIS
        friend class Disk;
        friend class FileSystem;
        friend class Geometry;
#endif

        private:
        Device(const PedDevice *device);
        Device(const Device &device);
        Device& operator=(const Device &device);

        typedef enum {
            PED_DEVICE_UNKNOWN      = 0,
            PED_DEVICE_SCSI         = 1,
            PED_DEVICE_IDE          = 2,
            PED_DEVICE_DAC960       = 3,
            PED_DEVICE_CPQARRAY     = 4,
            PED_DEVICE_FILE         = 5,
            PED_DEVICE_ATARAID      = 6,
            PED_DEVICE_I2O          = 7
        } DeviceType;

        PedDevice           *device_;

        const PedDevice*    get_c_device    ( ) const;

        public:
        // ped_device_probe_all()
        /**
         * The default device constructor.
         * It tries to detect all devices and constructs a list which can be
         * accessed with get_next().
         * @see get_next()
         */
        explicit Device                     ( ) throw (std::runtime_error);

        // ped_device_get(char *name)
        /**
         * Device constructor which needs a string as an argument.
         * @param dev Usually a block device, e.g. /dev/hda
         * @return The device for the specific parameter. Throws an exception
         * if device doesn't exist.
         */
        explicit Device                     (const std::string &dev)
            throw (std::runtime_error);

        // ped_device_destroy(PedDevice *dev)
        /**
         * The default Device destructor.
         * Internally it destroys the underlying C device.
         */
        ~Device                             ( );

        /**
         * Tries to get the next device.
         * The method tries to get the next block device.
         * @return next device, if it's the last one throws a runtime_error.
         */
        Device&             get_next        ( ) throw (std::runtime_error);

        /**
         * Checks if device is busy.
         * The method checks whether the current device is busy or not.
         * @return false on failure, true on success
         */
        bool                is_busy         ( );

        /**
         * Attempts to open the device, to allow use of read().
         * May allocate resources. Any resources allocated here will be freed
         * by a final close().
         * open() may be called multiple times. It's a ref-count-like
         * mechanism.
         * @see close()
         * @return false on failure, true on return
         */
        bool                open            ( );

        /**
         * Closes the device.
         * If this is the final close, then resources allocated by open() are
         * freed.
         * @return false on failure, true on success
         */
        bool                close           ( );

        /**
         * Begins external access mode.
         * External access mode allows you to safely do IO on the device.
         * If a PedDevice is open, then you should not do any IO on that device,
         * e.g. by calling an external program like e2fsck, unless you put it in
         * external access mode.  You should not use any libparted commands that
         * do IO to a device while a device is in external access mode.
         * Also, you should not ped_device_close() a device, while it is in
         * external access mode.
         * @warning begin_external_access() does things like tell the kernel to
         * flush its caches.
         * @return false on failure, true on success
         */
        bool                begin_external_access   ( );

        /**
         * Ends external access mode.
         * @warning end_external_access() does things like tell the kernel
         * to flush its caches.
         * @return false on failure, true on success
         */
        bool                end_external_access     ( );

        /**
         * Returns the current model.
         * @return The name of the model of the current device.
         */
        const std::string   get_model       ( ) const;

        /**
         * Returns the current block device.
         * @return The block device, e.g. /dev/hda
         */
        const std::string   get_path        ( ) const;

        /**
         * Will most likely be removed.
         * @return The device type represented as a digit.
         */
        const DeviceType    get_type        ( ) const;

        /**
         * Returns the number of sectors.
         * @return The number of sectors as a long long type.
         */
        const Sector        get_length      ( ) const;

        protected:

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
