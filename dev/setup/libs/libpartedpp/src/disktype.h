#ifndef PED_DISKTYPE_H
#define PED_DISKTYPE_H

#include <stdexcept>
#include <string>
#include "device.h"

namespace Ped {

    /**
     * The class is useful to get information of a disk type or to get the next
     * disk type on the block device.
     * There are different types of partition tables (or disk labels). These
     * are presented by DiskType's.
     */
    class DiskType {

      friend class Disk;

      private:
      DiskType( );
      DiskType(const PedDiskType* type);
      DiskType(const DiskType &type);
      DiskType& operator=(const DiskType &type);

      typedef enum {
          PED_DISK_TYPE_EXTENDED       = 1,
          PED_DISK_TYPE_PARTITION_NAME = 2
      } DiskTypeFeature;

      PedDiskType           *type_;

      const PedDiskType*    get_c_disktype  ( ) const;

      public:
      // ped_disk_type_get(char *name)
      /**
       * Returns the disk type with name of "name".
       * @param name partition table type //FIXME
       * @return disk type of "name"
       */
      explicit DiskType                     (const std::string &name);

      /**
       * The default DiskType destructor.
       */
      ~DiskType                             ( );

      /**
       * Returns the next disk type.
       * @return first disk type if there's none, throws an runtime_error if it
       * is the last registered type.
       */
      DiskType&             get_next        ( ) throw (std::runtime_error);

      /**
       * Checks for a given DiskTypeFeature.
       * @return true if the partition table type has support for "feature",
       * false if it hasn't.
       */
      bool                  check_feature   (DiskTypeFeature &feature);

      /**
       * Returns the name of the partition table type.
       * @return name of partition table type
       */
      const std::string&    get_name        ( ) const;

      protected:

   };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
