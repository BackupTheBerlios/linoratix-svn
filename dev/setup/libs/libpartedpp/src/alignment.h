#ifndef PED_ALIGNMENT_H
#define PED_ALIGNMENT_H

#include <parted/parted.h>
#include "geometry.h"

namespace Ped {

    class Alignment {

        friend class Constraint;

        private:
        Alignment( );
        Alignment(const PedAlignment *align);
        Alignment& operator=(const Alignment &align);

        PedAlignment            *alignment_;

        const PedAlignment*     get_c_alignment ( ) const;

        public:
        // ped_alignment_init() + ped_alignment_destroy()
        explicit Alignment              (Sector offset,
                                         Sector grain_size);
        // ped_alignment_duplicate()
        explicit Alignment              (const Alignment &align);
        // ped_alignment_intersect()
        explicit Alignment              (const Alignment &a,
                                         const Alignment &b);
        // ped_alignment_destroy()
        ~Alignment                      ( );

        Sector          align_up        (Geometry& geom,
                                         Sector sector);
        Sector          align_down      (Geometry& geom,
                                         Sector sector);
        Sector          align_nearest   (Geometry& geom,
                                         Sector sector);
        bool            is_aligned      (Geometry& geom,
                                         Sector sector);

        protected:

    };

};

#endif

/* vim: set tabstop=4 et shiftwidth=4: */
