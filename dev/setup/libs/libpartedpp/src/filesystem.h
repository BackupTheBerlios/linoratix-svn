#ifndef PED_FILESYSTEM_H
#define PED_FILESYSTEM_H

#include "constraint.h"
#include "filesystemtype.h"
#include "geometry.h"
#include "timer.h"

namespace Ped {

    class FileSystem {

        private:
        FileSystem( );
        FileSystem(const PedFileSystem *fs);
        FileSystem(const FileSystem &fs);
        FileSystem& operator=(const FileSystem &fs);

        const PedFileSystem*    get_c_filesystem    ( ) const;

        PedFileSystem           *fs_;

        public:
        // ped_file_system_create()
        explicit FileSystem                         (Geometry &geom,
                                                     FileSystemType &type,
                                                     Timer &timer);
        // ped_file_system_copy()
        explicit FileSystem                         (Geometry &geom,
                                                     Timer &timer);

        ~FileSystem                                 ( );

        FileSystemType& probe                       (Geometry &geom)
            throw (std::runtime_error);
        Geometry&       probe_specific              (const FileSystemType &type,
                                                     Geometry &geom);
        bool            clobber                     (Geometry &geom);
        FileSystem&     open                        (Geometry &geom)
            throw (std::runtime_error);
        bool            close                       ( );
        bool            check                       (Timer &timer);
        bool            resize                      (Geometry &geom,
                                                     Timer &timer);
        Constraint&     get_create_constraint       (const FileSystemType &fs_type,
                                                     const Device &dev)
            throw (std::runtime_error);
        Constraint&     get_resize_constraint       ( )
            throw (std::runtime_error);
        Constraint&     get_copy_constraint         (const Device &dev)
            throw (std::runtime_error);
        const FileSystemType&   get_filesystem_type ( ) const;
        const Geometry& get_geometry                ( ) const;
        const bool      is_checked                  ( ) const;

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
