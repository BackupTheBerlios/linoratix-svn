#ifndef PED_PARTITION_H
#define PED_PARTITION_H

#include "geometry.h"
#include "filesystemtype.h"

namespace Ped {

  class Disk;

    class Partition {

        friend class Disk;

        private:
        Partition( );
        Partition(const PedPartition *part);
        Partition(const Partition &partition);
        Partition& operator=(const Partition &partition);

        typedef enum {
            PED_PARTITION_LOGICAL           = 0x01,
            PED_PARTITION_EXTENDED          = 0x02,
            PED_PARTITION_FREESPACE         = 0x04,
            PED_PARTITION_METADATA          = 0x08
        } PartitionType;

        typedef enum {
            PED_PARTITION_BOOT=1,
            PED_PARTITION_ROOT=2,
            PED_PARTITION_SWAP=3,
            PED_PARTITION_HIDDEN=4,
            PED_PARTITION_RAID=5,
            PED_PARTITION_LVM=6,
            PED_PARTITION_LBA=7
        } PartitionFlag;

        PedPartition        *part_;
        Disk                *disk;

        const PedPartition* get_c_partition     ( ) const;

        public:
        // ped_partition_new()
        Partition                               (Disk &disk,
                                                 PartitionType part_type,
                                                 const FileSystemType &fs_type,
                                                 Sector start, Sector end);
        // ped_partition_destroy()
        ~Partition                              ( );

        bool                is_active           ( );
        bool                set_flag            (PartitionFlag flag, int state);
        bool                get_flag            (PartitionFlag flag);
        bool                is_flag_available   (PartitionFlag flag);
        bool                set_system          (FileSystemType &fs_type);
        bool                set_name            (std::string &name);
        const std::string   get_name            ( );
        std::string         get_path            ( );
        bool                is_busy             ( );
        const std::string   get_type_name       (PartitionType part_type);
        const std::string   flag_get_name       (PartitionFlag flag);
        PartitionFlag       get_flag_by_name    (const std::string &name);
        PartitionFlag       get_next_flag       (PartitionFlag flag);

        const Disk&         get_disk            ( ) const;
        const Geometry&     get_geometry        ( ) const;
        const int           get_num             ( ) const;
        const PartitionType get_partition_type  ( ) const;
        const FileSystemType& get_file_system_type( ) const
            throw (std::runtime_error);
        const Partition&    get_ext_partition   ( ) const;

        protected:

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
