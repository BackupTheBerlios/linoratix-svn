#ifndef PED_DISK_H
#define PED_DISK_H

#include <stdexcept>
#include <string>
#include "constraint.h"
#include "device.h"
#include "disktype.h"
#include "partition.h"

namespace Ped {

    /**
     * You'll need the disk class for creating new partition tables on a
     * certain disk. A disk is always associated with a device, and has a
     * partition table. There are different types of partition tables (or
     * disk labels). These are presented by DiskType's.
     */
    class Disk {

#ifndef DOXYGEN_SHOULD_SKIP_THIS
        friend class Partition;
#endif

        private:
        Disk( );
        Disk(const PedDisk *disk);
        Disk& operator=(const Disk &disk);

        PedDisk          *disk_;

        const PedDisk*   get_c_disk                 ( ) const;

        public:
        // ped_disk_duplicate()
        /**
         * Creates an exact copy of the current disk.
         * Duplicates the given "disk" (deep copy).
         * @return duplicated disk
         */
        explicit Disk                               (const Disk &disk);

        // ped_disk_new()
        /**
         * Creates a new disk on the block device.
         * Constructs a Disk object from device, and reads the partition table.
         * @warning This can modify the cylinders, heads, sectors on the
         * device, because the partition table might indicate that the
         * exisiting values are incorrect.
         * @return new disk
         */
        explicit Disk                               (const Device &device);

        // ped_disk_new_fresh()
        /**
         * Creates a partition table on "device" with the DiskType type.
         * Creates a partition table on "device" and constructs a Disk object
         * for it.
         * @param device the device where the partition table should be created
         * on.
         * @param type the DiskType for the device.
         * @return new disk with given DiskType
         */
        explicit Disk                               (const Device &device,
                                                     DiskType &type);
        // ped_disk_destroy()
        /**
         * The default Disk destructor.
         * Internally it destroys the underlying C disk.
         */
        ~Disk                                       ( );

        /**
         * Returns the type of the partition table detected on "device".
         * @return type of the partition table detected on "device", throws
         * runtime_error on failure.
         */
        DiskType&    probe                          (Device &device)
            throw (std::runtime_error);

        /**
         * Overwrites all partition table signatures on "device".
         * @return false on failure, true on success
         */
        bool         clobber                        (Device &device);

        /**
         * Overwrites all partition table signatures on "device", except the
         * signature for "type".
         * @return false on failure, true on success
         */
        bool         clobber_exclude                (Device &device,
                                                     const DiskType &type);
        /**
         * Writes the partition table to the current disk.
         * Informs the operating system of the new layout. This is implemented
         * by calling commit_to_dev() and then commit_to_os().
         * @return false on failure, true on success
         */
        bool         commit                         ( );

        /**
         * Writes the partition table to the current disk.
         * @return false on failure, true on success
         */
        bool         commit_to_dev                  ( );

        /**
         * Tells the operating system kernel about the partition table layout
         * of the current disk.
         * This is rather loosely defined... depending on which operating
         * system, etc. For example, on old versions of Linux, it simply calls
         * the BLKRRPART ioctl, which tells the kernel to reread the partition
         * table. On newer versions (2.4.x), it will use the new blkpg
         * interface to tell LInux where each partition starts/ends, etc. In
         * this case, Linux need not have support for this type of partition
         * table.
         * @return false on failure, true on success
         */
        bool         commit_to_os                   ( );

        /**
         * Checks for errors on partition table.
         * @warning Most error checking occurs when the partition table is
         * loaded from disk when it is constructed.
         * @return false on errors, true if there are none
         */
        bool         check                          ( );

        /**
         * Prints a summary of the current disk's partitions.
         * Useful for debugging.
         */
        void         print                          ( );

        /**
         * Add partition to the current disk.
         * "part"'s geometry may be changed, subject to "constraint".
         * You could set "constraint" to constraint_exact(), but many partition
         * table schemes have special requirements on the start and end of
         * partitions. Therefore, having an overly strict constraint will
         * probably mean that add_partition() will fail (in which case, "part"
         * will be left unmodified)
         * "part" is assigned a number in this process. get_num() in Partition.
         * @return false on failure, true on success
         */
        bool         add_partition                  (const Partition &part,
                                                     const Constraint &constraint);

        /**
         * Removes "part" from the current disk.
         * If "part" is an extended partition, it must contain no logical
         * partitions.
         * "part" is *NOT* destroyed. The called must call delete_partition()
         * instead.
         * @see delete_partition()
         * @return false on failure, true on sucess
         */
        bool         remove_partition               (const Partition &part);

        /**
         * Removes "part" from the current disk and destroys "part".
         * @return false on failure, true on success
         */
        bool         delete_partition               (const Partition &part);

        /**
         * Removes and destroys all partitions on the current disk.
         * @return false on failure, true on success
         */
        bool         delete_all                     ( );

        /**
         * Sets the geometry of "part".
         * This can fail for many reasons, e.g. can't overlap with other
         * partitions.  If it does fail, "part" will remain unchanged. "part"'s
         * geometry may be set to something different from "start" and "end"
         * subject to "constraint".
         * @return false on failure, true on success
         */
        bool         set_partition_geom             (const Partition &part,
                                                     const Constraint &constraint,
                                                     const Sector start,
                                                     const Sector end);

        /**
         * Mimimizes the partition "part".
         * Grows "part"'s geometry to the maximum possible subject to
         * "constraint".  The new geometry will be a superset of the old
         * geometry.
         * @return false on failure, true on success
         */
        bool         maximize_partition             (const Partition &part,
                                                     const Constraint &constraint);

        /**
         * Returns the maximum geometry "part" can be grown to.
         * @return maximum geometry "part" can be grown to, subject to
         * "constraint", throws runtime_error on failure.
         */
        Geometry&    get_max_partition_geometry     (Partition &part,
                                                     Constraint &constraint)
            throw (std::runtime_error);

        /**
         * Reduces the extended partition on "disk" to the minimum possible.
         * @return false on failure, true on success
         */
        bool         minimize_extended_partition    ( );

        /**
         * Returns the next partition after "part" on the current disk.
         * @return if there's no "part", returns the first partition. If "part"
         * is the last partition, throws a runtime_error. If "part" is an
         * extended partition, returns the first logical partition.
         * If this is called repeatedly passing the return value as "part", a
         * depth-first traversal is executed.
         */
        Partition&   get_next_partition             (Partition &part)
            throw (std::runtime_error);

        /**
         * Returns the partition numbered "num".
         * @return partition numbered "num", otherwise throws a runtime_error
         */
        Partition&   get_partition                  (int num)
            throw (std::runtime_error);

        /**
         * Returns the partition that 'owns' "sect".
         * @return partition that owns "sect", otherwise throws a runtime_error
         */
        Partition&   get_partition_by_sector        (Sector sect)
            throw (std::runtime_error);

        /**
         * Returns the extended partition.
         * @return extended partition, if there isn't one throws an
         * runtime_error if there
         */
        Partition&   get_extended_partition         ( )
            throw (std::runtime_error);

        /**
         * Returns the number of primary partitions.
         * @return number of primary partitions
         */
        int          get_primary_partition_count    ( );

        /**
         * Returns the maxinum number of primary partitions.
         * @return maxinum number of primary partitions this partition table can
         * have
         */
        int          get_max_primary_partition_count( );

        /**
         * Returns last partition number.
         * @return last partition number of all partitions
         */
        int          get_last_partition_num         ( );

        /**
         * Returns current device.
         * @return current device on which operations are done
         */
        const Device&    get_device                 ( ) const;

        /**
         * Returns current disktype.
         * @return disktype of current partition
         */
        const DiskType&  get_disktype               ( ) const;

        protected:

    };
};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
