#ifndef PED_GEOMETRY_H
#define PED_GEOMETRY_H

#include "device.h"
#include "timer.h"

namespace Ped {

    class Geometry {

        friend class Alignment;
        friend class Constraint;
        friend class Disk;
        friend class FileSystem;
        friend class Partition;

        private:
        Geometry( );
        Geometry(const PedGeometry *geom);
        Geometry(const Geometry &geom);
        Geometry& operator=(const Geometry &geom);

        PedGeometry         *geom_;

        const PedGeometry*  get_c_geometry      ( ) const;

        public:
        // ped_geometry_new() + ped_geometry_init()
        explicit Geometry                       (Device &dev,
                                                 Sector start,
                                                 Sector length);
        // ped_geometry_duplicate()
        explicit Geometry                       (Geometry &geom);
        // ped_geometry_intersect()
        explicit Geometry                       (const Geometry &a,
                                                 const Geometry &b);
        // ped_geometry_destroy()
        ~Geometry                               ( );

        void                set                 (Sector start,
                                                 Sector length);
        void                set_start           (Sector start);
        void                set_end             (Sector end);
        bool                test_overlap        (Geometry &a,
                                                 Geometry &b);
        bool                test_inside         (Geometry &a,
                                                 Geometry &b);
        bool                test_equal          (Geometry &a,
                                                 Geometry &b);
        bool                test_sector_inside  (Sector sect);
        bool                read                (void *buffer,
                                                 Sector offset,
                                                 Sector count);
        bool                write               (void *buffer,
                                                 Sector offset,
                                                 Sector count);
        Sector              check               (void *buffer,
                                                 Sector buffer_size,
                                                 Sector offset,
                                                 Sector granularity,
                                                 Sector count,
                                                 Timer &timer);
        bool                sync                ( );
        Sector              map                 (Geometry &dst,
                                                 Geometry &src,
                                                 Sector sector);
        const Device&       get_device          ( ) const;
        const Sector        get_start           ( ) const;
        const Sector        get_length          ( ) const;
        const Sector        get_end             ( ) const;

        protected:

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
